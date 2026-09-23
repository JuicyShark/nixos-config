# Smart focus

**0.1.0-rc.2** is the current milestone candidate for this workstation's Hyprland,
Ghostty, Neovim and single-client Zellij workflow. See [release notes](CHANGELOG.md).

`Super + arrows` resolves Neovim splits, then a containing Zellij pane, then
Hyprland windows. Plain arrows stay application-owned. The existing
`Super + Ctrl + Alt + arrows` always dispatches directly to Hyprland.

| Workflow | Milestone status |
| --- | --- |
| Standalone Neovim splits | User verified |
| Standalone Zellij panes | User verified |
| Neovim splits nested in Zellij | User verified |
| Zellij pane into Neovim | User verified |
| Hyprland takes over at the outer edge | User verified |

After activating an update, open a fresh terminal so its shell can register
before Zellij auto-starts. Existing sessions can be reattached from that window.
The registration hook follows Atuin's PTY proxy setup. Direct Neovim launches
also register through their terminal UI. Launching Zellij directly as the
terminal command, bypassing the configured shell, does not run that hook.

If navigation does not behave as expected, run `smart-focus doctor` in the
affected terminal. It reads service and ownership state without changing focus.
An `error` makes it exit with status 1; a `warning` describes a supported safety
boundary or a version mismatch. Re-run after changing focus if the context check
caught a transition. A healthy report verifies routing prerequisites, not every
application's response to a future keypress.

```sh
smart-focus --version
smart-focus doctor
smart-focus doctor --json   # structured health checks
smart-focus status          # broker version and recent outcomes
journalctl --user -u smart-focus
```

To recover immediately, use the direct Hyprland shortcut above. If the broker
is not responding, inspect `systemctl --user status smart-focus.service` and
restart it with `systemctl --user restart smart-focus.service`. If registration
is missing, open a fresh terminal. If focus context is missing, reload the
activated Hyprland configuration. Reloading a configuration that still contains
an older module will restore that older behavior.

## Routing contract

Hyprland submits requests asynchronously to the Rust user service. It keeps a
bounded queue, captures the source window and focus generation, and accepts
completions only before their deadline. Confirmed edges bubble outward;
timeouts, stale ownership and uncertain replies retain focus. An unavailable
broker falls back to native focus only when no request was accepted. The broker
deduplicates recent requests and keeps persistent Neovim MessagePack-RPC
connections. Neither the broker nor the editor executes shell command strings.

Terminal ownership is established by an OSC title nonce written to that
terminal's tty, matched against Hyprland's client list, then restored using the
terminal title stack. The active window is never used as evidence of ownership.
Shell startup establishes this association; direct Neovim launches can establish
it through their attached TUI. Neovim's detached editor server and its TUI have
separate PID/start-time checks. Foreground process-group checks exclude suspended
editors. Multiple editors register independently rather than overwriting a
single per-window entry.

During shell startup, job control can give the helper foreground status while
its parent shell waits. Registration accepts that exact parent/helper handoff;
unrelated background processes do not qualify.

Zellij is discovered independently of Neovim: the foreground client is associated
with its server using Linux Unix-socket peer information. This survives
detach/reattach and does not trust inherited session variables for attachment
identity. The native adapter uses a persistent Protobuf connection to Zellij's
`contract_version_1` socket, tested against 0.45.1. It sends movements to the
explicitly selected client, drains each acknowledgement before reusing the
connection, and verifies focus before and after movement. No Zellij subprocess
is launched for navigation. Cached ownership requires unchanged client/server
process lifetimes and the continued presence of both connected socket endpoints.

Once a broker request is accepted, its application deadline controls execution.
Caller disconnects and slow input cannot interrupt recording the outcome.
Connection count, frame sizes and waiting time are bounded.

## Known boundaries

- Zellij sessions with multiple attached clients retain focus because attaching
  terminal processes cannot yet be mapped unambiguously to Zellij client IDs.
  The native protocol can target an ID; that alone does not prove ownership.
  The compositor escape remains available.
- Zellij's query/move/query sequence is not an atomic transaction against mouse
  input. Explicit client targeting prevents movement from being redirected to
  another newly active client, but an atomic expected-pane check still requires
  support inside Zellij's server. This implementation does not claim that guarantee.
- Multiple native Ghostty surfaces within one window are conservatively blocked;
  Ghostty's configured workflow uses desktop windows and Zellij panes.
- Neovim floating windows and modal prompts retain focus. Tabs do not wrap.
- Other applications use native desktop navigation. Additional editor adapters,
  remote editors, pane relocation and pane resizing are not implemented here.

Home Manager installs `smart-focus.service` as part of the Hyprland profile.
Activation and fresh terminal/editor processes are required for the new
registration format; old registrations are not trusted or migrated
heuristically.

## Validation and milestone readiness

```sh
nix build .#checks.x86_64-linux.smart-focus \
  .#checks.x86_64-linux.smart-focus-integration \
  .#checks.x86_64-linux.hyprland-runtime \
  .#checks.x86_64-linux.nixvim-smoke --no-link
```

The integration check uses isolated PTYs and real Neovim/Zellij processes. It
covers split and edge movement, suspended editors, stale source context, window
isolation, shell-only Zellij, detach/reattach, nested editor routing and refusal
to guess between multiple Zellij clients. Hyprland tests exercise request
ordering, duplicate/late completion rejection, timeouts and broker unavailability.
The shell test uses real foreground job control with a mocked compositor title
acknowledgement; the live Ghostty check separately verified actual ownership and
left/right movement through the configured Atuin → shell → Zellij startup.

Before promoting the candidate to 0.1.0, verify a clean desktop login, a broker
restart, and a Hyprland reload using the same activated candidate. Keep the five
user-verified workflows above working during ordinary use. Multiple-client
Zellij support is a later milestone, not an implied capability of this release.
