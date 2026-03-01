{pkgs}:
pkgs.writeShellScriptBin "tmux-terminal-action" ''
  #!/usr/bin/env bash
  set -euo pipefail

  action="''${1:-attach-main}"
  target_session="''${TMUX_TARGET_SESSION:-main}"

  spawn_terminal_tmux_session() {
    local session="$1"
    local workdir="$2"
    exec kitty -d=current -e tmux new-session -A -s "$session" -c "$workdir"
  }

  ensure_session() {
    tmux has-session -t "$target_session" 2>/dev/null || tmux new-session -d -s "$target_session"
  }

  spawn_terminal_tmux_main() {
    spawn_terminal_tmux_session "$target_session" "''${PWD:-$HOME}"
  }

  case "$action" in
    smart)
      spawn_terminal_tmux_main
      ;;
    attach)
      spawn_terminal_tmux_main
      ;;
    attach-main)
      spawn_terminal_tmux_main
      ;;
    new-client)
      spawn_terminal_tmux_main
      ;;
    split-h)
      ensure_session
      tmux split-window -h -t "$target_session": -c "#{pane_current_path}"
      ;;
    split-v)
      ensure_session
      tmux split-window -v -t "$target_session": -c "#{pane_current_path}"
      ;;
    new-window)
      ensure_session
      tmux new-window -t "$target_session": -c "#{pane_current_path}"
      ;;
    new-window-detached)
      ensure_session
      tmux new-window -d -t "$target_session": -c "#{pane_current_path}"
      ;;
    prev-window)
      ensure_session
      tmux previous-window -t "$target_session":
      ;;
    next-window)
      ensure_session
      tmux next-window -t "$target_session":
      ;;
    choose-tree)
      ensure_session
      exec kitty -d=current -e tmux choose-tree -Zw
      ;;
    choose-session)
      ensure_session
      exec kitty -d=current -e tmux choose-tree -sZw
      ;;
    *)
      exit 2
      ;;
  esac
''
