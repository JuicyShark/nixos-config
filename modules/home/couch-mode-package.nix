{
  pkgs,
  hyprctl,
  steam,
  tvOutput,
  topic,
  mqttPublisher ? null,
}:
pkgs.writeShellApplication {
  name = "couch-mode";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.jq
  ];
  text = ''
    tv_output=${pkgs.lib.escapeShellArg tvOutput}
    action="''${1:?usage: couch-mode enter|exit|display-on|display-off|display-toggle}"

    set_display_profile() {
      "${hyprctl}" eval "Juicy.monitors.setProfile(\"$1\")"
    }

    tv_output_active() {
      "${hyprctl}" monitors -j | jq -e --arg output "$tv_output" \
        'any(.[]; .name == $output and .disabled == false and .dpmsStatus == true)' >/dev/null
    }

    wait_for_tv_output() {
      attempts=0
      while [ "$attempts" -lt 80 ]; do
        if tv_output_active; then
          return 0
        fi
        attempts=$((attempts + 1))
        sleep 0.1
      done
      echo "couch-mode: $tv_output did not become active within 8 seconds" >&2
      return 1
    }

    publish() {
      ${
      if mqttPublisher == null
      then ":"
      else ''${pkgs.lib.escapeShellArg mqttPublisher} ${pkgs.lib.escapeShellArg topic} "$1" false''
    }
    }

    big_picture_ready() {
      "${hyprctl}" clients -j | jq -e \
        'any(.[];
          .class == "steam"
          and (.title == "Steam Big Picture Mode" or .initialTitle == "Steam Big Picture Mode")
        )' >/dev/null
    }

    wait_for_big_picture() {
      attempts=0
      while [ "$attempts" -lt 150 ]; do
        if big_picture_ready; then
          return 0
        fi
        attempts=$((attempts + 1))
        sleep 0.1
      done
      echo "couch-mode: Steam Big Picture did not become ready within 15 seconds" >&2
      return 1
    }

    display_on() {
      # When configured, HA owns physical TV power/input. A broker outage
      # must not prevent enabling an already-connected output.
      publish enter || true
      set_display_profile extended || return 1
      wait_for_tv_output
    }

    display_off() {
      set_display_profile solo
      # This remains a non-destructive state notification; HA must not infer
      # that leaving the display profile means the TV should enter standby.
      publish exit || true
    }

    rollback_entry() {
      set_display_profile solo || true
    }

    case "$action" in
      display-on)
        display_on
        ;;
      display-off)
        display_off
        ;;
      display-toggle)
        if tv_output_active; then
          display_off
        else
          display_on
        fi
        ;;
      enter)
        if ! display_on; then
          rollback_entry
          exit 1
        fi
        "${steam}" -gamepadui >/dev/null 2>&1 &
        if ! wait_for_big_picture; then
          rollback_entry
          exit 1
        fi
        ;;
      exit)
        display_off
        ;;
      *)
        echo "usage: couch-mode enter|exit|display-on|display-off|display-toggle" >&2
        exit 2
        ;;
    esac
  '';
}
