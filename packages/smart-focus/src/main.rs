//! Application I/O stays out of Hyprland. Only acknowledged edges bubble out.
mod diagnostics;
mod linux;
mod zellij;
use anyhow::{Context, Result, bail, ensure};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::{
    collections::{HashMap, VecDeque},
    fs,
    io::Write,
    os::unix::{
        fs::{MetadataExt, PermissionsExt},
        io::AsRawFd,
    },
    path::{Path, PathBuf},
    sync::Arc,
    time::Duration,
};
use tokio::{
    io::{AsyncBufReadExt, AsyncReadExt, AsyncWriteExt, BufReader},
    net::{UnixListener, UnixStream},
    sync::{Mutex, Semaphore},
    time::timeout,
};

fn now() -> f64 {
    let mut ts = libc::timespec {
        tv_sec: 0,
        tv_nsec: 0,
    };
    unsafe {
        libc::clock_gettime(libc::CLOCK_MONOTONIC, &mut ts);
    }
    ts.tv_sec as f64 + ts.tv_nsec as f64 / 1e9
}
fn runtime() -> PathBuf {
    PathBuf::from(std::env::var_os("XDG_RUNTIME_DIR").expect("XDG_RUNTIME_DIR required"))
        .join("smart-focus")
}
fn instance_dir(instance: &str) -> Result<PathBuf> {
    ensure!(
        !instance.is_empty()
            && instance
                .bytes()
                .all(|b| b.is_ascii_alphanumeric() || b"_.-".contains(&b)),
        "invalid instance"
    );
    Ok(runtime().join(instance))
}
fn private_dir(path: &Path) -> Result<()> {
    fs::create_dir_all(path)?;
    fs::set_permissions(path, fs::Permissions::from_mode(0o700))?;
    Ok(())
}
fn nonce() -> Result<String> {
    Ok(fs::read_to_string("/proc/sys/kernel/random/uuid")?
        .trim()
        .to_owned())
}
fn atomic_json(path: &Path, value: &impl Serialize) -> Result<()> {
    private_dir(path.parent().context("no parent")?)?;
    let temp = path.with_extension(format!("{}.tmp", nonce()?));
    fs::write(&temp, serde_json::to_vec(value)?)?;
    fs::rename(temp, path)?;
    Ok(())
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Process {
    pid: u32,
    #[serde(default)]
    ppid: u32,
    start: String,
    tty: u64,
    pgrp: i32,
    foreground: i32,
    state: String,
}
fn parse_proc(pid: u32, stat: &str) -> Option<Process> {
    let fields: Vec<_> = stat.rsplit_once(") ")?.1.split_whitespace().collect();
    Some(Process {
        pid,
        ppid: fields.get(1)?.parse().ok()?,
        start: fields.get(19)?.to_string(),
        tty: fields.get(4)?.parse::<i64>().ok()? as u64,
        pgrp: fields.get(2)?.parse().ok()?,
        foreground: fields.get(5)?.parse().ok()?,
        state: fields.first()?.to_string(),
    })
}
fn process(pid: u32) -> Option<Process> {
    parse_proc(pid, &fs::read_to_string(format!("/proc/{pid}/stat")).ok()?)
}
fn descendant(mut pid: u32, ancestor: u32) -> bool {
    for _ in 0..64 {
        let Some(p) = process(pid) else { return false };
        if p.ppid == ancestor {
            return true;
        }
        if p.ppid <= 1 || p.ppid == pid {
            return false;
        }
        pid = p.ppid;
    }
    false
}
fn alive(p: &Process, foreground: bool) -> bool {
    process(p.pid).is_some_and(|q| {
        q.start == p.start
            && q.tty == p.tty
            && !["Z", "X"].contains(&q.state.as_str())
            && (!foreground
                || (q.tty != 0
                    && q.pgrp == q.foreground
                    && !["T", "t"].contains(&q.state.as_str())))
    })
}
#[derive(Debug, Clone, Deserialize, Serialize)]
struct Request {
    instance: String,
    id: String,
    context: String,
    window: String,
    direction: String,
    operation: String,
    deadline: f64,
}
impl Request {
    fn valid(&self) -> bool {
        instance_dir(&self.instance).is_ok()
            && !self.window.is_empty()
            && self.window.bytes().all(|b| b.is_ascii_hexdigit())
            && ["left", "right", "up", "down"].contains(&self.direction.as_str())
            && ["focus", "cwd"].contains(&self.operation.as_str())
            && self.deadline.is_finite()
    }
    fn current(&self) -> bool {
        self.deadline > now()
            && instance_dir(&self.instance)
                .ok()
                .and_then(|p| fs::read_to_string(p.join("context")).ok())
                .is_some_and(|s| s.trim_end() == self.context)
    }
}
fn result(status: &str) -> Value {
    json!({"status": status})
}
fn explained(status: &str, reason: &str) -> Value {
    json!({"status": status, "reason": reason})
}
async fn hypr(instance: &str, command: &str) -> Result<String> {
    instance_dir(instance)?;
    let path = runtime()
        .parent()
        .unwrap()
        .join("hypr")
        .join(instance)
        .join(".socket.sock");
    let mut stream = UnixStream::connect(path).await?;
    stream.write_all(command.as_bytes()).await?;
    let mut out = String::new();
    stream.read_to_string(&mut out).await?;
    Ok(out)
}
fn parse_clients(text: &str) -> Result<HashMap<u32, String>> {
    let mut lines = text.lines();
    ensure!(
        lines
            .next()
            .is_some_and(|line| line.starts_with("CLIENT_ID ZELLIJ_PANE_ID")),
        "invalid Zellij client list header"
    );
    let mut clients = HashMap::new();
    for line in lines.filter(|line| !line.trim().is_empty()) {
        let mut parts = line.split_whitespace();
        let id: u32 = parts.next().context("missing client ID")?.parse()?;
        let raw = parts.next().context("missing pane ID")?;
        let pane = if raw.bytes().all(|b| b.is_ascii_digit()) {
            format!("terminal_{raw}")
        } else {
            raw.to_owned()
        };
        ensure!(
            pane.strip_prefix("terminal_")
                .or_else(|| pane.strip_prefix("plugin_"))
                .is_some_and(|n| !n.is_empty() && n.bytes().all(|b| b.is_ascii_digit())),
            "invalid Zellij pane ID"
        );
        ensure!(
            clients.insert(id, pane).is_none(),
            "duplicate Zellij client ID"
        );
    }
    Ok(clients)
}

struct Rpc {
    stream: UnixStream,
    buffer: Vec<u8>,
    sequence: u64,
}
impl Rpc {
    async fn connect(path: &str) -> Result<Self> {
        Ok(Self {
            stream: UnixStream::connect(path).await?,
            buffer: Vec::new(),
            sequence: 0,
        })
    }
    async fn call(&mut self, payload: Value) -> Result<Value> {
        self.sequence += 1;
        let request = json!([
            0,
            self.sequence,
            "nvim_exec_lua",
            [
                "return require('juicy.smart_focus').request(...)",
                [payload]
            ]
        ]);
        let value = rmpv::ext::to_value(request)?;
        let mut encoded = Vec::new();
        rmpv::encode::write_value(&mut encoded, &value)?;
        self.stream.write_all(&encoded).await?;
        loop {
            let mut cursor = std::io::Cursor::new(&self.buffer);
            match rmpv::decode::read_value(&mut cursor) {
                Ok(value) => {
                    let used = cursor.position() as usize;
                    let response: Value = rmpv::ext::from_value(value)?;
                    self.buffer.drain(..used);
                    if response[0] == 1 && response[1] == self.sequence {
                        ensure!(response[2].is_null(), "editor RPC error");
                        return Ok(response[3].clone());
                    }
                }
                Err(error) if self.buffer.len() > 1024 * 1024 => {
                    bail!("oversized RPC response: {error}")
                }
                Err(_) => {
                    let mut data = [0; 8192];
                    let count = self.stream.read(&mut data).await?;
                    ensure!(count > 0, "editor disconnected");
                    self.buffer.extend_from_slice(&data[..count]);
                }
            }
        }
    }
}
#[derive(Clone, Deserialize)]
struct Editor {
    pid: u32,
    start: String,
    tty: u64,
    ui_pid: u32,
    ui_start: String,
    socket: String,
    session: Option<String>,
    pane: Option<String>,
    focus_generation: u64,
}
impl Editor {
    fn live(&self) -> bool {
        process(self.pid).is_some_and(|p| p.start == self.start && alive(&p, false))
            && process(self.ui_pid)
                .is_some_and(|p| p.start == self.ui_start && p.tty == self.tty && alive(&p, true))
    }
}
fn records<T: serde::de::DeserializeOwned>(dir: &Path) -> Vec<T> {
    fs::read_dir(dir)
        .into_iter()
        .flatten()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().is_some_and(|s| s == "json"))
        .filter_map(|e| {
            fs::read(e.path())
                .ok()
                .and_then(|s| serde_json::from_slice(&s).ok())
        })
        .collect()
}
fn editor_for(tty: Option<u64>, pane: Option<(&str, &str, u32)>) -> Result<Option<Editor>> {
    let mut matches = records::<Editor>(&runtime().join("editors"))
        .into_iter()
        .filter(|e| {
            let owned = if let Some((session, pane, server_pid)) = pane {
                e.session.as_deref() == Some(session)
                    && e.pane.as_deref() == Some(pane)
                    && descendant(e.ui_pid, server_pid)
            } else {
                tty == Some(e.tty) && e.session.is_none()
            };
            owned
                && e.live()
                && e.socket
                    == runtime()
                        .parent()
                        .unwrap()
                        .join(format!("nvim-smart-focus-{}.sock", e.pid))
                        .to_string_lossy()
        });
    let found = matches.next();
    ensure!(matches.next().is_none(), "ambiguous editor ownership");
    Ok(found)
}
#[derive(Default)]
struct Broker {
    connections: HashMap<String, Rpc>,
    zellij_connections: HashMap<(u32, String), zellij::Connection>,
    attachments: HashMap<u32, (String, linux::Session)>,
    recent: VecDeque<Value>,
    completed: VecDeque<(String, String, Value)>,
}
impl Broker {
    async fn nvim(&mut self, editor: &Editor, req: &Request) -> Result<Value> {
        self.connections.retain(|path, _| Path::new(path).exists());
        if !self.connections.contains_key(&editor.socket) {
            self.connections
                .insert(editor.socket.clone(), Rpc::connect(&editor.socket).await?);
        }
        let mut payload = serde_json::to_value(req)?;
        payload["pid"] = json!(editor.pid);
        payload["start"] = json!(editor.start);
        payload["ui_pid"] = json!(editor.ui_pid);
        payload["ui_start"] = json!(editor.ui_start);
        payload["focus_generation"] = json!(editor.focus_generation);
        let answer = self
            .connections
            .get_mut(&editor.socket)
            .unwrap()
            .call(payload)
            .await;
        if answer.is_err() {
            self.connections.remove(&editor.socket);
        }
        answer
    }
    async fn route(&mut self, req: &Request) -> Result<Value> {
        if !req.current() {
            return Ok(result("stale"));
        }
        let root = instance_dir(&req.instance)?;
        let terminals: Vec<_> = records::<Process>(&root.join("terminals").join(&req.window))
            .into_iter()
            .filter(|p| alive(p, false))
            .collect();
        let Some(terminal) = terminals.first() else {
            return Ok(explained(
                "edge",
                "No live terminal registration for this window",
            ));
        };
        if terminals.iter().any(|p| p.tty != terminal.tty) {
            return Ok(
                json!({"status":"blocked","reason":"Ghostty native surfaces require an adapter"}),
            );
        }
        let foreground = process(terminal.pid).context("terminal exited")?.foreground;
        let attachment = u32::try_from(foreground)
            .ok()
            .and_then(process)
            .filter(|p| p.tty == terminal.tty && alive(p, true) && linux::is_zellij(p.pid));
        if let Some(attachment) = attachment {
            let pid = attachment.pid;
            self.attachments
                .retain(|pid, (start, _)| process(*pid).is_some_and(|p| &p.start == start));
            let cached = self
                .attachments
                .get(&pid)
                .filter(|(start, owner)| start == &attachment.start && owner.still_connected(pid))
                .map(|(_, owner)| owner.clone());
            let owner = match cached {
                Some(owner) => Some(owner),
                None => tokio::task::spawn_blocking(move || linux::session(pid)).await??,
            };
            let Some(owner) = owner else {
                return Ok(explained(
                    "blocked",
                    "The foreground Zellij client has no verified server connection",
                ));
            };
            self.attachments
                .insert(pid, (attachment.start.clone(), owner.clone()));
            self.zellij_connections
                .retain(|(pid, start), _| process(*pid).is_some_and(|p| &p.start == start));
            let key = (owner.server_pid, owner.server_start.clone());
            let mut connection = match self.zellij_connections.remove(&key) {
                Some(connection) => connection,
                None => zellij::Connection::connect(&owner).await?,
            };
            let answer = self
                .route_zellij(req, &attachment, &owner, &mut connection)
                .await;
            if answer.is_ok() {
                self.zellij_connections.insert(key, connection);
            }
            return answer;
        }
        if let Some(editor) = editor_for(Some(terminal.tty), None)? {
            return self.nvim(&editor, req).await;
        }
        Ok(result(if req.operation == "focus" {
            "edge"
        } else {
            "blocked"
        }))
    }
    async fn route_zellij(
        &mut self,
        req: &Request,
        attachment: &Process,
        owner: &linux::Session,
        connection: &mut zellij::Connection,
    ) -> Result<Value> {
        let session = owner.name.as_str();
        let before = connection.clients().await?;
        if before.len() != 1 {
            return Ok(
                json!({"status":"blocked","reason":"Multiple Zellij clients need an explicit terminal-to-client association"}),
            );
        }
        let (client, pane) = before.iter().next().unwrap();
        let Some(pane_id) = pane.strip_prefix("terminal_") else {
            return Ok(explained("blocked", "The active Zellij pane is a plugin"));
        };
        let editor = editor_for(None, Some((session, pane_id, owner.server_pid)))?;
        if !req.current()
            || !alive(attachment, true)
            || !owner.still_connected(attachment.pid)
            || connection.clients().await? != before
        {
            return Ok(result("stale"));
        }
        if let Some(editor) = editor {
            let answer = self.nvim(&editor, req).await?;
            if answer["status"] != "edge" || req.operation == "cwd" {
                return Ok(answer);
            }
        } else if req.operation == "cwd" {
            return Ok(result("blocked"));
        }
        if !req.current()
            || !alive(attachment, true)
            || !process(owner.server_pid).is_some_and(|p| p.start == owner.server_start)
            || connection.clients().await? != before
        {
            return Ok(result("stale"));
        }
        connection.focus(*client, &req.direction).await?;
        let after = connection.clients().await?;
        if after.len() != 1 || !after.contains_key(client) {
            return Ok(result("unknown"));
        }
        Ok(result(if after.get(client) == Some(pane) {
            "edge"
        } else {
            "moved"
        }))
    }
    async fn dispatch(&mut self, req: Request) -> Value {
        let started = now();
        if !req.valid() {
            return result("blocked");
        }
        let key = format!("{}/{}", req.instance, req.id);
        let fingerprint = serde_json::to_string(&req).expect("serializable request");
        if let Some((_, previous, answer)) = self.completed.iter().find(|(id, _, _)| id == &key) {
            return if previous == &fingerprint {
                answer.clone()
            } else {
                result("blocked")
            };
        }
        let duration = Duration::from_secs_f64((req.deadline - started).clamp(0.0, 0.2));
        let answer = match timeout(duration, self.route(&req)).await {
            Ok(Ok(value)) => value,
            Ok(Err(error)) => json!({"status":"unknown","reason":error.to_string()}),
            Err(_) => {
                self.connections.clear();
                self.zellij_connections.clear();
                json!({"status":"unknown","reason":"deadline expired"})
            }
        };
        self.recent.push_back(json!({"id":req.id,"window":req.window,"direction":req.direction,"result":answer,"elapsed_ms":(now()-started)*1000.0}));
        while self.recent.len() > 50 {
            self.recent.pop_front();
        }
        self.completed.push_back((key, fingerprint, answer.clone()));
        while self.completed.len() > 128 {
            self.completed.pop_front();
        }
        answer
    }
}
async fn exchange(request: Value) -> Result<Value> {
    let stream = UnixStream::connect(runtime().join("broker.sock")).await?;
    let mut stream = BufReader::new(stream);
    stream
        .get_mut()
        .write_all(format!("{}\n", request).as_bytes())
        .await?;
    let mut out = String::new();
    stream.read_line(&mut out).await?;
    Ok(serde_json::from_str(&out)?)
}
async fn serve() -> Result<()> {
    private_dir(&runtime())?;
    let lock = fs::File::create(runtime().join("daemon.lock"))?;
    ensure!(
        unsafe { libc::flock(lock.as_raw_fd(), libc::LOCK_EX | libc::LOCK_NB) } == 0,
        "broker already running"
    );
    let path = runtime().join("broker.sock");
    let _ = fs::remove_file(&path);
    let listener = UnixListener::bind(&path)?;
    let broker = Arc::new(Mutex::new(Broker::default()));
    let capacity = Arc::new(Semaphore::new(64));
    loop {
        let (stream, _) = listener.accept().await?;
        if stream.peer_cred()?.uid() != unsafe { libc::getuid() } {
            continue;
        }
        let Ok(permit) = capacity.clone().try_acquire_owned() else {
            continue;
        };
        let broker = broker.clone();
        tokio::spawn(async move {
            let _permit = permit;
            let _ = async move {
                let mut stream = BufReader::new(stream);
                let mut input = Vec::new();
                timeout(
                    Duration::from_millis(300),
                    (&mut stream).take(16385).read_until(b'\n', &mut input),
                )
                .await??;
                ensure!(input.len() <= 16384, "oversized request");
                let value: Value = serde_json::from_slice(&input)?;
                let mut broker = timeout(Duration::from_millis(250), broker.lock()).await?;
                // Once accepted, dispatch owns its application deadline and
                // records the outcome even if the caller disconnects. A read
                // or reply timeout must never cancel mutation bookkeeping.
                let answer = if value["operation"] == "status" {
                    json!({"version":env!("CARGO_PKG_VERSION"),"recent":broker.recent})
                } else {
                    broker.dispatch(serde_json::from_value(value)?).await
                };
                drop(broker);
                timeout(
                    Duration::from_millis(100),
                    stream.get_mut().write_all(format!("{answer}\n").as_bytes()),
                )
                .await??;
                Ok::<_, anyhow::Error>(())
            }
            .await;
        });
    }
}
fn lua_quote(value: &str) -> String {
    format!(
        "\"{}\"",
        value
            .bytes()
            .map(|b| format!("\\{b:03}"))
            .collect::<String>()
    )
}
async fn request_focus(args: &[String]) -> Result<()> {
    ensure!(
        args.len() == 6,
        "request expects instance id context deadline direction operation"
    );
    let window = args[2]
        .split('\t')
        .nth(2)
        .context("invalid context")?
        .to_owned();
    let req = Request {
        instance: args[0].clone(),
        id: args[1].clone(),
        context: args[2].clone(),
        window,
        deadline: args[3].parse()?,
        direction: args[4].clone(),
        operation: args[5].clone(),
    };
    ensure!(req.valid(), "invalid request");
    let answer = match timeout(
        Duration::from_millis(250),
        exchange(serde_json::to_value(&req)?),
    )
    .await
    {
        Ok(Ok(answer)) => answer,
        Ok(Err(error))
            if error.downcast_ref::<std::io::Error>().is_some_and(|e| {
                [
                    std::io::ErrorKind::NotFound,
                    std::io::ErrorKind::ConnectionRefused,
                ]
                .contains(&e.kind())
            }) =>
        {
            result("unavailable")
        }
        _ => result("unknown"),
    };
    let code = format!(
        "eval Juicy.smartFocusComplete({},{},{})",
        lua_quote(&req.id),
        lua_quote(answer["status"].as_str().unwrap_or("unknown")),
        lua_quote(answer["cwd"].as_str().unwrap_or(""))
    );
    timeout(Duration::from_millis(300), hypr(&req.instance, &code)).await??;
    Ok(())
}
async fn register_terminal(pid: u32) -> Result<()> {
    let Ok(instance) = std::env::var("HYPRLAND_INSTANCE_SIGNATURE") else {
        return Ok(());
    };
    if std::env::var_os("ZELLIJ").is_some() {
        return Ok(());
    }
    let record = process(pid).context("terminal process exited")?;
    // An interactive shell gives this helper the foreground process group
    // while waiting for it. The shell still owns the same terminal; accept
    // only its direct, foreground helper as evidence of that handoff.
    let foreground_helper = process(std::process::id()).is_some_and(|helper| {
        helper.ppid == record.pid && helper.tty == record.tty && alive(&helper, true)
    });
    ensure!(
        alive(&record, false) && (alive(&record, true) || foreground_helper),
        "terminal owner is not foreground"
    );
    let mut tty = fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(format!("/proc/{pid}/fd/0"))?;
    ensure!(tty.metadata()?.rdev() == record.tty, "caller tty mismatch");
    let folder = instance_dir(&instance)?.join("terminals");
    for window in fs::read_dir(&folder)
        .into_iter()
        .flatten()
        .filter_map(|e| e.ok())
    {
        if records::<Process>(&window.path())
            .iter()
            .any(|p| p.tty == record.tty && alive(p, false))
        {
            return Ok(());
        }
    }
    let marker = format!("smart-focus-{}", nonce()?);
    tty.write_all(format!("\x1b[22;2t\x1b]2;{marker}\x07").as_bytes())?;
    let outcome = timeout(Duration::from_millis(400), async {
        for _ in 0..30 {
            let windows: Vec<Value> = serde_json::from_str(&hypr(&instance, "j/clients").await?)?;
            let matches: Vec<_> = windows
                .iter()
                .filter(|w| w["title"] == marker && w["class"] == "com.mitchellh.ghostty")
                .collect();
            if matches.len() == 1 {
                let id = matches[0]["stableId"]
                    .as_str()
                    .context("missing stable ID")?;
                ensure!(
                    !id.is_empty() && id.bytes().all(|b| b.is_ascii_hexdigit()),
                    "invalid stable ID"
                );
                atomic_json(&folder.join(id).join(format!("{pid}.json")), &record)?;
                return Ok::<_, anyhow::Error>(());
            }
            tokio::time::sleep(Duration::from_millis(10)).await;
        }
        bail!("terminal title handshake was not acknowledged")
    })
    .await;
    tty.write_all(b"\x1b[23;2t")?;
    outcome??;
    Ok(())
}
#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<()> {
    unsafe {
        libc::umask(0o077);
    }
    let args: Vec<String> = std::env::args().skip(1).collect();
    match args.first().map(String::as_str) {
        None | Some("--help" | "-h" | "help") => println!("{}", diagnostics::HELP),
        Some("--version" | "-V" | "version") => {
            println!("smart-focus {}", env!("CARGO_PKG_VERSION"))
        }
        Some("doctor") => {
            ensure!(
                args.len() == 1 || (args.len() == 2 && args[1] == "--json"),
                "usage: smart-focus doctor [--json]"
            );
            diagnostics::doctor(args.len() == 2).await?;
        }
        Some("serve") => serve().await?,
        Some("inspect") => println!(
            "{:?}",
            linux::session(args.get(1).context("PID required")?.parse()?)?.map(|s| s.name)
        ),
        Some("status") => println!(
            "{}",
            serde_json::to_string_pretty(
                &timeout(
                    Duration::from_millis(750),
                    exchange(json!({"operation":"status"}))
                )
                .await
                .context("broker did not respond within 750 ms")??
            )?
        ),
        Some("register-terminal") => {
            register_terminal(args.get(1).context("PID required")?.parse()?).await?;
        }
        Some("request") => request_focus(&args[1..]).await?,

        _ => bail!("unknown command; run smart-focus --help"),
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn proc_parser_handles_spaces_and_parentheses() {
        let p = parse_proc(
            123,
            "123 (editor (worker)) S 1 2 3 34816 2 6 7 8 9 10 11 12 13 14 15 16 17 18 4242",
        )
        .unwrap();
        assert_eq!(p.start, "4242");
        assert_eq!(p.tty, 34816);
        assert_eq!(p.pgrp, p.foreground);
    }
    #[test]
    fn process_lifetime_rejects_reused_pid() {
        let mut p = process(std::process::id()).unwrap();
        assert!(alive(&p, false));
        p.start.push('0');
        assert!(!alive(&p, false));
    }
    #[test]
    fn client_parser_preserves_plugin_identity() {
        let c = parse_clients(
            "CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND\n0 7 nvim\n1 plugin_7 plugin\n",
        )
        .unwrap();
        assert_eq!(c[&0], "terminal_7");
        assert_eq!(c[&1], "plugin_7");
    }
    #[test]
    fn malformed_clients_cannot_look_like_a_single_client() {
        for rows in [
            "0 terminal_1 nvim\n0 terminal_2 bash",
            "0 terminal_1 nvim\nbad row",
            "0 unknown_pane bash",
        ] {
            assert!(
                parse_clients(&format!("CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND\n{rows}"))
                    .is_err()
            );
        }
    }
    #[test]
    fn lua_arguments_cannot_inject_code() {
        let input = "\"); os.execute('bad') --\n";
        let encoded = lua_quote(input);
        assert!(!encoded.contains("os.execute"));
        assert!(!encoded.contains('\n'));
    }
    #[tokio::test]
    async fn rpc_ignores_notifications_and_matches_reply_id() {
        let (client, mut server) = UnixStream::pair().unwrap();
        let responder = tokio::spawn(async move {
            let mut bytes = [0; 4096];
            assert!(server.read(&mut bytes).await.unwrap() > 0);
            for message in [
                json!([2, "notification", []]),
                json!([1,77,null,{"status":"edge"}]),
                json!([1,1,null,{"status":"moved"}]),
            ] {
                let mut out = vec![];
                rmpv::encode::write_value(&mut out, &rmpv::ext::to_value(message).unwrap())
                    .unwrap();
                // Fragmented messages exercise stream framing.
                for chunk in out.chunks(3) {
                    server.write_all(chunk).await.unwrap();
                }
            }
        });
        let mut rpc = Rpc {
            stream: client,
            buffer: vec![],
            sequence: 0,
        };
        assert_eq!(rpc.call(json!({})).await.unwrap()["status"], "moved");
        responder.await.unwrap();
    }
    #[tokio::test]
    async fn disconnected_editor_is_not_an_edge() {
        let (client, server) = UnixStream::pair().unwrap();
        drop(server);
        let mut rpc = Rpc {
            stream: client,
            buffer: vec![],
            sequence: 0,
        };
        assert!(rpc.call(json!({})).await.is_err());
    }
    #[tokio::test]
    async fn expired_request_does_not_contact_apps() {
        let req = Request {
            instance: "test".into(),
            id: "1".into(),
            context: "unused".into(),
            window: "abc".into(),
            direction: "left".into(),
            operation: "focus".into(),
            deadline: 0.0,
        };
        let mut broker = Broker::default();
        assert_eq!(broker.dispatch(req.clone()).await["status"], "stale");
        assert_eq!(broker.dispatch(req.clone()).await["status"], "stale");
        let mut collision = req;
        collision.direction = "right".into();
        assert_eq!(broker.dispatch(collision).await["status"], "blocked");
        assert_eq!(
            broker.recent.len(),
            1,
            "duplicate requests are not executed twice"
        );
        assert!(broker.connections.is_empty());
    }
}
