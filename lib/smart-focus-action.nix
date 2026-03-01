{pkgs}:
pkgs.writeShellScriptBin "smart-focus-action" ''
  #!/usr/bin/env bash
  set -euo pipefail

  direction="''${1:-}"
  mode="''${2:-auto}"

  terminal_classes="''${SMART_FOCUS_TERMINAL_CLASSES:-^(kitty|com\.mitchellh\.ghostty|org\.wezfurlong\.wezterm|org\.alacritty|foot)$}"

  log() {
    if [ "''${SMART_FOCUS_DEBUG:-0}" = "1" ]; then
      printf '[smart-focus] %s\n' "$*" >&2
    fi
  }

  case "$direction" in
    l | left)
      hypr_dir="l"
      niri_action="focus-column-left"
      key="left"
      ;;
    d | down)
      hypr_dir="d"
      niri_action="focus-window-down"
      key="down"
      ;;
    u | up)
      hypr_dir="u"
      niri_action="focus-window-up"
      key="up"
      ;;
    r | right)
      hypr_dir="r"
      niri_action="focus-column-right"
      key="right"
      ;;
    *)
      log "invalid direction: $direction"
      exit 2
      ;;
  esac

  detect_compositor() {
    case "''${SMART_FOCUS_COMPOSITOR:-}" in
      hyprland | niri)
        printf '%s\n' "$SMART_FOCUS_COMPOSITOR"
        return
        ;;
    esac

    if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      printf 'hyprland\n'
      return
    fi

    if [ -n "''${NIRI_SOCKET:-}" ]; then
      printf 'niri\n'
      return
    fi

    case "''${XDG_CURRENT_DESKTOP:-}" in
      *Hyprland* | *hyprland*)
        printf 'hyprland\n'
        return
        ;;
      *Niri* | *niri*)
        printf 'niri\n'
        return
        ;;
    esac

    printf 'unknown\n'
  }

  move_hypr() {
    hyprctl dispatch movefocus "$hypr_dir" >/dev/null 2>&1
  }

  move_niri() {
    niri msg action "$niri_action" >/dev/null 2>&1
  }

  move_compositor_focus() {
    compositor="$(detect_compositor)"
    log "compositor=$compositor direction=$direction mode=$mode"

    case "$compositor" in
      hyprland)
        move_hypr || true
        ;;
      niri)
        move_niri || true
        ;;
      *)
        log "no known compositor detected"
        ;;
    esac
  }

  hypr_active_window_has_tmux() {
    active_json="$(hyprctl activewindow -j 2>/dev/null || true)"
    [ -n "$active_json" ] || return 1

    win_class="$(printf '%s' "$active_json" | jq -r '.class // ""')"
    if ! printf '%s\n' "$win_class" | grep -Eiq "$terminal_classes"; then
      return 1
    fi

    win_pid="$(printf '%s' "$active_json" | jq -r '.pid // 0')"
    if [ "$win_pid" -le 0 ] 2>/dev/null; then
      return 1
    fi

    pids=("$win_pid")
    visited=" "
    while [ "''${#pids[@]}" -gt 0 ]; do
      pid="''${pids[0]}"
      pids=("''${pids[@]:1}")

      case "$visited" in
        *" $pid "*)
          continue
          ;;
      esac
      visited="$visited$pid "

      comm="$(ps -o comm= -p "$pid" 2>/dev/null || true)"
      if printf '%s\n' "$comm" | grep -q '^tmux'; then
        log "tmux detected under pid=$pid class=$win_class"
        return 0
      fi

      children="$(pgrep -P "$pid" 2>/dev/null || true)"
      if [ -n "$children" ]; then
        for child in $children; do
          [ -n "$child" ] && pids+=("$child")
        done
      fi
    done

    return 1
  }

  maybe_send_tmux_shortcut_hypr() {
    if hypr_active_window_has_tmux; then
      hyprctl dispatch sendshortcut "CTRL, $key, activewindow" >/dev/null 2>&1 && return 0
    fi

    return 1
  }

  case "$mode" in
    auto)
      if [ "$(detect_compositor)" = "hyprland" ] && maybe_send_tmux_shortcut_hypr; then
        exit 0
      fi
      move_compositor_focus
      ;;
    compositor-only)
      move_compositor_focus
      ;;
    *)
      log "invalid mode: $mode"
      exit 2
      ;;
  esac
''
