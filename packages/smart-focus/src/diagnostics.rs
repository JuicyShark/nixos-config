//! Read-only checks: never dispatch focus or send an editor movement request.
use super::*;

pub const HELP: &str = "Smart focus — Neovim splits, Zellij panes, then Hyprland windows

Usage: smart-focus <command>

  doctor [--json]   Check the service and focused window without moving focus
  status           Show broker version and recent outcomes as JSON
  inspect PID      Identify a foreground Zellij client's session
  --version        Print the installed version
  --help           Show this help

Super + arrows navigates panes and windows.
Super + Ctrl + Alt + arrows always navigates Hyprland directly.

Service and adapter commands:
  serve
  register-terminal PID
  request INSTANCE ID CONTEXT DEADLINE DIRECTION OPERATION";

fn check(checks: &mut Vec<Value>, name: &str, status: &str, detail: impl Into<String>) {
    checks.push(json!({"name":name,"status":status,"detail":detail.into()}));
}

async fn inspect_environment() -> Vec<Value> {
    let mut checks = Vec::new();
    if std::env::var_os("XDG_RUNTIME_DIR").is_none() {
        check(
            &mut checks,
            "runtime",
            "error",
            "XDG_RUNTIME_DIR is unset; run this inside your desktop session",
        );
        return checks;
    }
    match timeout(
        Duration::from_millis(750),
        exchange(json!({"operation":"status"})),
    )
    .await
    {
        Ok(Ok(status)) => {
            let version = status["version"]
                .as_str()
                .unwrap_or("unreported (older broker)");
            check(
                &mut checks,
                "broker",
                "ok",
                format!("Responding; version {version}"),
            );
            if version != env!("CARGO_PKG_VERSION") {
                check(
                    &mut checks,
                    "version",
                    "warning",
                    "CLI and running broker differ; activate the new configuration and restart smart-focus.service",
                );
            }
        }
        _ => check(
            &mut checks,
            "broker",
            "error",
            "Not responding; check systemctl --user status smart-focus.service",
        ),
    }
    let Ok(instance) = std::env::var("HYPRLAND_INSTANCE_SIGNATURE") else {
        check(
            &mut checks,
            "hyprland",
            "error",
            "HYPRLAND_INSTANCE_SIGNATURE is unset; run this inside Hyprland",
        );
        return checks;
    };
    let window = match timeout(
        Duration::from_millis(750),
        hypr(&instance, "j/activewindow"),
    )
    .await
    {
        Ok(Ok(text)) => serde_json::from_str::<Value>(&text).ok(),
        _ => None,
    };
    let Some(window) = window else {
        check(
            &mut checks,
            "hyprland",
            "error",
            "Cannot query the running compositor",
        );
        return checks;
    };
    check(&mut checks, "hyprland", "ok", "Compositor is responding");
    let Some(id) = window["stableId"].as_str().filter(|id| !id.is_empty()) else {
        check(&mut checks, "window", "info", "No focused window");
        return checks;
    };
    let Ok(directory) = instance_dir(&instance) else {
        check(
            &mut checks,
            "context",
            "error",
            "Invalid Hyprland instance identifier",
        );
        return checks;
    };
    let context = fs::read_to_string(directory.join("context")).unwrap_or_default();
    if context.trim_end().split('\t').nth(2) == Some(id) {
        check(
            &mut checks,
            "context",
            "ok",
            "Hyprland adapter has published the focused window",
        );
    } else {
        check(
            &mut checks,
            "context",
            "error",
            "Focus context is missing or out of date; reload the Hyprland configuration, then retry",
        );
    }
    if window["class"] != "com.mitchellh.ghostty" {
        check(
            &mut checks,
            "routing",
            "info",
            "This application uses native Hyprland navigation",
        );
        return checks;
    }
    let terminals: Vec<_> = records::<Process>(&directory.join("terminals").join(id))
        .into_iter()
        .filter(|p| alive(p, false))
        .collect();
    let Some(terminal) = terminals.first() else {
        check(
            &mut checks,
            "terminal",
            "error",
            "No live registration; open a fresh Ghostty window after activating the shell configuration",
        );
        return checks;
    };
    if terminals.iter().any(|p| p.tty != terminal.tty) {
        check(
            &mut checks,
            "terminal",
            "warning",
            "Multiple native terminal surfaces share this window; use the direct Hyprland shortcut",
        );
        return checks;
    }
    check(
        &mut checks,
        "terminal",
        "ok",
        "Window ownership is registered and its process is alive",
    );
    let foreground = process(terminal.pid)
        .and_then(|p| u32::try_from(p.foreground).ok())
        .and_then(process);
    if let Some(client) = foreground.filter(|p| linux::is_zellij(p.pid)) {
        match tokio::task::spawn_blocking(move || linux::session(client.pid)).await {
            Ok(Ok(Some(owner))) => match zellij::inspect(&owner).await {
                Ok(clients) if clients.len() == 1 => check(
                    &mut checks,
                    "zellij",
                    "ok",
                    "Verified server connection and exactly one attached client",
                ),
                Ok(_) => check(
                    &mut checks,
                    "zellij",
                    "warning",
                    "Session has zero or multiple clients; terminal-to-client association is ambiguous",
                ),
                Err(_) => check(
                    &mut checks,
                    "zellij",
                    "error",
                    "Verified the server, but its native socket did not respond or uses an unsupported contract",
                ),
            },
            _ => check(
                &mut checks,
                "zellij",
                "error",
                "Cannot verify the foreground client's server connection",
            ),
        }
    } else {
        match editor_for(Some(terminal.tty), None) {
            Ok(Some(_)) => check(
                &mut checks,
                "neovim",
                "ok",
                "A live foreground Neovim UI is registered on this terminal",
            ),
            Ok(None) => check(
                &mut checks,
                "routing",
                "info",
                "No foreground editor is registered; directional focus goes to Hyprland",
            ),
            Err(_) => check(
                &mut checks,
                "neovim",
                "warning",
                "Editor ownership is ambiguous; focus will be retained",
            ),
        }
    }
    checks
}

pub async fn doctor(as_json: bool) -> Result<()> {
    let checks = inspect_environment().await;
    let healthy = !checks.iter().any(|c| c["status"] == "error");
    if as_json {
        println!(
            "{}",
            serde_json::to_string_pretty(
                &json!({"version":env!("CARGO_PKG_VERSION"),"healthy":healthy,"checks":checks})
            )?
        );
    } else {
        println!(
            "Smart focus {} — read-only check",
            env!("CARGO_PKG_VERSION")
        );
        for c in &checks {
            println!(
                "[{}] {}: {}",
                c["status"].as_str().unwrap(),
                c["name"].as_str().unwrap(),
                c["detail"].as_str().unwrap()
            );
        }
    }
    if !healthy {
        std::process::exit(1);
    }
    Ok(())
}
