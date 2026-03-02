{ pkgs }:
pkgs.writeShellScriptBin "smart-focus-action" ''
  #!/usr/bin/env bash
  set -euo pipefail

  direction="''${1:-}"
  mode="''${2:-auto}"

  terminal_classes="''${SMART_FOCUS_TERMINAL_CLASSES:-^(kitty|com\.mitchellh\.ghostty|org\.wezfurlong\.wezterm|org\.alacritty|foot)$}"
  emacs_classes="''${SMART_FOCUS_EMACS_CLASSES:-^(emacs|org\.gnu\.Emacs)$}"

  log() {
    if [ "''${SMART_FOCUS_DEBUG:-0}" = "1" ]; then
      local ts
      ts="$(date +%H:%M:%S.%3N 2>/dev/null || date +%H:%M:%S)"
      printf '[smart-focus %s] %s\n' "$ts" "$*" >&2

      if [ -n "''${SMART_FOCUS_DEBUG_FILE:-}" ]; then
        printf '[smart-focus %s] %s\n' "$ts" "$*" >> "$SMART_FOCUS_DEBUG_FILE" 2>/dev/null || true
      fi
    fi
  }

  debug_tmux_clients() {
    if [ "''${SMART_FOCUS_DEBUG:-0}" != "1" ]; then
      return
    fi

    local clients
    clients="$(tmux list-clients -F '#{client_pid} #{client_tty} #{client_session}' 2>/dev/null || true)"
    if [ -n "$clients" ]; then
      log "tmux clients: $clients"
    else
      log "tmux clients: <none>"
    fi
  }

  case "$direction" in
    l | left)
      hypr_dir="l"
      key="left"
      emacs_dir="left"
      emacs_symbol="'left"
      ;;
    d | down)
      hypr_dir="d"
      key="down"
      emacs_dir="below"
      emacs_symbol="'below"
      ;;
    u | up)
      hypr_dir="u"
      key="up"
      emacs_dir="above"
      emacs_symbol="'above"
      ;;
    r | right)
      hypr_dir="r"
      key="right"
      emacs_dir="right"
      emacs_symbol="'right"
      ;;
    *)
      log "invalid direction: $direction"
      exit 2
      ;;
  esac

  move_hypr() {
    hyprctl dispatch movefocus "$hypr_dir" >/dev/null 2>&1 || true
  }

  proc_comm() {
    local pid="''${1:-0}"
    local comm_file="/proc/$pid/comm"

    [ -r "$comm_file" ] || return 1
    IFS= read -r REPLY < "$comm_file" || return 1
    return 0
  }

  proc_ppid() {
    local pid="''${1:-0}"
    local status_file="/proc/$pid/status"
    local key value

    [ -r "$status_file" ] || return 1
    while IFS=$'\t' read -r key value; do
      if [ "$key" = "PPid:" ]; then
        REPLY="$value"
        return 0
      fi
    done < "$status_file"

    return 1
  }

  proc_children() {
    local pid="''${1:-0}"
    local file line children_accum

    children_accum=""
    for file in /proc/$pid/task/*/children; do
      [ -e "$file" ] || continue
      [ -r "$file" ] || continue
      IFS= read -r line < "$file" || line=""
      [ -n "$line" ] || continue
      children_accum="$children_accum $line"
    done

    if [ -n "$children_accum" ]; then
      REPLY="''${children_accum# }"
      return 0
    fi

    return 1
  }

  scan_descendants_flags() {
    local root_pid="''${1:-0}"
    local pid comm children child
    local -a queue
    local visited

    desc_has_tmux=0
    desc_has_emacs=0

    if [ "$root_pid" -le 0 ] 2>/dev/null; then
      return 0
    fi

    queue=("$root_pid")
    visited=" "

    while [ "''${#queue[@]}" -gt 0 ]; do
      pid="''${queue[0]}"
      queue=("''${queue[@]:1}")

      case "$visited" in
        *" $pid "*)
          continue
          ;;
      esac
      visited="$visited$pid "

      if proc_comm "$pid"; then
        comm="$REPLY"
      else
        comm=""
      fi

      if [ "$desc_has_tmux" -eq 0 ] && [[ "$comm" =~ ^tmux(:.*)?$ ]]; then
        desc_has_tmux=1
      fi
      if [ "$desc_has_emacs" -eq 0 ] && [[ "$comm" =~ ^emacs(|client|-([0-9]+(\.[0-9]+)*))$ ]]; then
        desc_has_emacs=1
      fi

      if [ "$desc_has_tmux" -eq 1 ] && [ "$desc_has_emacs" -eq 1 ]; then
        return 0
      fi

      if proc_children "$pid"; then
        children="$REPLY"
      else
        children=""
      fi

      if [ -n "$children" ]; then
        for child in $children; do
          [ -n "$child" ] && queue+=("$child")
        done
      fi
    done

    return 0
  }

  pid_is_descendant_of() {
    local pid="''${1:-0}"
    local ancestor="''${2:-0}"
    local seen

    if [ "$pid" -le 0 ] 2>/dev/null || [ "$ancestor" -le 0 ] 2>/dev/null; then
      return 1
    fi

    seen=" "
    while [ "$pid" -gt 1 ] 2>/dev/null; do
      if [ "$pid" = "$ancestor" ]; then
        return 0
      fi

      case "$seen" in
        *" $pid "*)
          break
          ;;
      esac
      seen="$seen$pid "

      if proc_ppid "$pid"; then
        pid="$REPLY"
      else
        break
      fi
    done

    return 1
  }

  tmux_client_attached_to_active_window() {
    local clients line client_pid client_tty client_session rest

    clients="$(tmux list-clients -F '#{client_pid} #{client_tty} #{client_session}' 2>/dev/null || true)"
    [ -n "$clients" ] || return 1

    while IFS= read -r line; do
      [ -n "$line" ] || continue

      client_pid="''${line%% *}"
      rest="''${line#* }"
      client_tty="''${rest%% *}"
      client_session="''${rest#* }"

      if [ -z "$client_pid" ]; then
        continue
      fi

      if pid_is_descendant_of "$client_pid" "$active_pid"; then
        log "tmux client match pid=$client_pid tty=$client_tty session=$client_session"
        return 0
      fi
    done <<< "$clients"

    return 1
  }

  ensure_active_context() {
    [ "''${active_context_loaded:-0}" = "1" ] && return 0

    local active_json active_ctx_tsv

    active_context_loaded=1
    active_json="$(hyprctl activewindow -j 2>/dev/null || true)"
    [ -n "$active_json" ] || return 1

    active_ctx_tsv="$(printf '%s' "$active_json" | jq -r '[.class // "", (.pid // 0 | tostring)] | @tsv' 2>/dev/null || true)"
    [ -n "$active_ctx_tsv" ] || return 1

    IFS=$'\t' read -r active_class active_pid <<< "$active_ctx_tsv"
    log "active window class=$active_class pid=$active_pid"

    active_is_emacs_class=0
    active_is_terminal=0
    desc_has_tmux=0
    desc_has_emacs=0

    if [[ "$active_class" =~ $emacs_classes ]]; then
      active_is_emacs_class=1
      log "active classified as emacs class"
      return 0
    fi

    if [[ "$active_class" =~ $terminal_classes ]]; then
      active_is_terminal=1
      scan_descendants_flags "$active_pid"
      log "active terminal flags tmux=$desc_has_tmux emacs_proc=$desc_has_emacs"
    else
      log "active not terminal/emacs class"
    fi

    return 0
  }

  maybe_move_emacs_focus() {
    ensure_active_context || return 1

    if [ "$active_is_emacs_class" -ne 1 ] && [ "$desc_has_emacs" -ne 1 ]; then
      return 1
    fi

    if [ "$active_is_emacs_class" -eq 1 ]; then
      log "emacs-class window detected: class=$active_class"
    else
      log "emacs process detected under terminal class=$active_class pid=$active_pid"
    fi

    result="$(${pkgs.coreutils}/bin/timeout 0.08s ${pkgs.emacs}/bin/emacsclient --eval "(let ((target (window-in-direction ''${emacs_symbol}))) (when target (select-window target) t))" 2>/dev/null || true)"
    if [ "$result" = "t" ]; then
      log "moved emacs focus direction=$emacs_dir"
      return 0
    fi

    return 1
  }

  maybe_move_tmux_focus() {
    ensure_active_context || return 1

    if [ "$active_is_terminal" -ne 1 ]; then
      return 1
    fi

    if [ "$desc_has_tmux" -eq 1 ] || tmux_client_attached_to_active_window; then
      log "tmux detected for terminal class=$active_class pid=$active_pid"
      hyprctl dispatch sendshortcut "CTRL, $key, activewindow" >/dev/null 2>&1 && return 0
    fi

    log "tmux not detected for active window; fallback to hypr focus"
    debug_tmux_clients
    return 1
  }

  case "$mode" in
    auto)
      log "start auto direction=$direction"

      if maybe_move_emacs_focus; then
        log "decision=emacs"
        exit 0
      fi

      if maybe_move_tmux_focus; then
        log "decision=tmux"
        exit 0
      fi

      log "decision=hypr"
      move_hypr
      ;;
    compositor-only)
      move_hypr
      ;;
    *)
      log "invalid mode: $mode"
      exit 2
      ;;
  esac
''
