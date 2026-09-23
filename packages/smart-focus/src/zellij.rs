//! Minimal native client for Zellij's versioned contract_version_1 protocol.
//! Field numbers/framing are from Zellij v0.45.1, commit efd8fd5a89a20c07a111d248ad7fce53848d2c18:
//! zellij-utils/src/client_server_contract/{client_to_server,server_to_client,common_types}.proto
//! and ipc.rs. Unknown protobuf fields are ignored; unknown replies fail closed.
use super::*;
use prost::Message;

#[derive(Clone, PartialEq, Message)]
struct ClientMessage {
    #[prost(message, optional, tag = "9")]
    action: Option<ActionMessage>,
}
#[derive(Clone, PartialEq, Message)]
struct ActionMessage {
    #[prost(message, optional, tag = "1")]
    action: Option<Action>,
    #[prost(uint32, optional, tag = "3")]
    client_id: Option<u32>,
    // is_cli_client (tag 4) must be false. True makes the server prefer the
    // last active client over an explicit client_id (route.rs).
}
#[derive(Clone, PartialEq, Message)]
struct Action {
    #[prost(oneof = "ActionType", tags = "10, 86")]
    kind: Option<ActionType>,
}
#[derive(Clone, PartialEq, prost::Oneof)]
enum ActionType {
    #[prost(message, tag = "10")]
    MoveFocus(MoveFocus),
    #[prost(message, tag = "86")]
    ListClients(Empty),
}
#[derive(Clone, PartialEq, Message)]
struct MoveFocus {
    #[prost(uint32, tag = "1")]
    direction: u32,
}
#[derive(Clone, PartialEq, Message)]
struct Empty {}
#[derive(Clone, PartialEq, Message)]
struct Lines {
    #[prost(string, repeated, tag = "1")]
    lines: Vec<String>,
}
#[derive(Clone, PartialEq, Message)]
struct ServerMessage {
    #[prost(message, optional, tag = "2")]
    complete: Option<Empty>,
    #[prost(message, optional, tag = "3")]
    exit: Option<Empty>,
    #[prost(message, optional, tag = "5")]
    log: Option<Lines>,
    #[prost(message, optional, tag = "6")]
    error: Option<Lines>,
}

pub struct Connection {
    stream: UnixStream,
}
pub async fn inspect(owner: &linux::Session) -> Result<HashMap<u32, String>> {
    timeout(Duration::from_millis(500), async {
        Connection::connect(owner).await?.clients().await
    })
    .await?
}
impl Connection {
    pub async fn connect(owner: &linux::Session) -> Result<Self> {
        ensure!(
            owner
                .path
                .parent()
                .and_then(Path::file_name)
                .is_some_and(|p| p == "contract_version_1"),
            "unsupported Zellij socket contract"
        );
        let stream = UnixStream::connect(&owner.path).await?;
        ensure!(
            stream.peer_cred()?.pid() == Some(owner.server_pid as i32),
            "Zellij server identity changed"
        );
        ensure!(
            process(owner.server_pid).is_some_and(|p| p.start == owner.server_start),
            "Zellij server lifetime changed"
        );
        Ok(Self { stream })
    }
    async fn action(&mut self, kind: ActionType, client_id: Option<u32>) -> Result<String> {
        let bytes = ClientMessage {
            action: Some(ActionMessage {
                action: Some(Action { kind: Some(kind) }),
                client_id,
            }),
        }
        .encode_to_vec();
        self.stream
            .write_all(&(bytes.len() as u32).to_le_bytes())
            .await?;
        self.stream.write_all(&bytes).await?;
        let mut lines = Vec::new();
        // Each action completes with UnblockInputThread. Drain through that
        // boundary, including Log replies, before reusing the connection.
        for _ in 0..16 {
            let size = self.stream.read_u32_le().await? as usize;
            ensure!(size <= 1024 * 1024, "oversized Zellij response");
            let mut bytes = vec![0; size];
            self.stream.read_exact(&mut bytes).await?;
            let reply = ServerMessage::decode(bytes.as_slice())?;
            ensure!(reply.exit.is_none(), "Zellij disconnected");
            if let Some(error) = reply.error {
                bail!("Zellij: {}", error.lines.join("; "));
            }
            if let Some(log) = reply.log {
                lines.extend(log.lines);
            }
            if reply.complete.is_some() {
                return Ok(lines.join("\n"));
            }
        }
        bail!("Zellij did not acknowledge the action")
    }
    pub async fn clients(&mut self) -> Result<HashMap<u32, String>> {
        let reply = self.action(ActionType::ListClients(Empty {}), None).await?;
        ensure!(
            reply.starts_with("CLIENT_ID"),
            "Zellij returned an invalid client list"
        );
        parse_clients(&reply)
    }
    pub async fn focus(&mut self, client_id: u32, direction: &str) -> Result<()> {
        let direction = match direction {
            "left" => 1,
            "right" => 2,
            "up" => 3,
            "down" => 4,
            _ => bail!("invalid direction"),
        };
        self.action(
            ActionType::MoveFocus(MoveFocus { direction }),
            Some(client_id),
        )
        .await?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[tokio::test]
    async fn oversized_or_disconnected_native_reply_is_not_an_edge() {
        let (client, mut server) = UnixStream::pair().unwrap();
        server.write_all(&u32::MAX.to_le_bytes()).await.unwrap();
        let mut connection = Connection { stream: client };
        assert!(connection.focus(1, "left").await.is_err());
        drop(server);
        assert!(connection.clients().await.is_err());
    }
    #[tokio::test]
    async fn drains_completion_before_next_action_and_targets_client() {
        let (client, mut server) = UnixStream::pair().unwrap();
        let peer = tokio::spawn(async move {
            for expected in [None, Some(7)] {
                let size = server.read_u32_le().await.unwrap();
                let mut bytes = vec![0; size as usize];
                server.read_exact(&mut bytes).await.unwrap();
                assert_eq!(
                    ClientMessage::decode(bytes.as_slice())
                        .unwrap()
                        .action
                        .unwrap()
                        .client_id,
                    expected
                );
                let replies = [
                    ServerMessage {
                        log: Some(Lines {
                            lines: vec![
                                "CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND\n7 terminal_1 N/A".into(),
                            ],
                        }),
                        ..Default::default()
                    },
                    ServerMessage {
                        complete: Some(Empty {}),
                        ..Default::default()
                    },
                ];
                for reply in replies {
                    let bytes = reply.encode_to_vec();
                    server
                        .write_all(&(bytes.len() as u32).to_le_bytes())
                        .await
                        .unwrap();
                    for byte in bytes {
                        server.write_all(&[byte]).await.unwrap();
                    }
                }
            }
        });
        let mut connection = Connection { stream: client };
        assert_eq!(connection.clients().await.unwrap()[&7], "terminal_1");
        connection.focus(7, "left").await.unwrap();
        peer.await.unwrap();
    }
}
