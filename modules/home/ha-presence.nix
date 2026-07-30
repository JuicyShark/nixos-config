# Home-side wiring for HA presence reporting via MQTT. Reads
# osConfig.modules.haPresence and provides:
#   - ha-presence-update <state>  on $PATH  (publishes retained MQTT message)
#   - ha-presence-discover        publishes HA discovery config (retained, once)
#   - Noctalia hooks for shell started/lock/unlock/session-exit transitions
#   - Noctalia idle behaviors for idle/sleep with on-resume → active
#   - systemd user drop-in for wayland-wm@hyprland.service ExecStopPost → offline
#
# Topics:
#   homeassistant/sensor/<deviceId>/config   ← discovery (retained)
#   homeassistant/sensor/<deviceId>/state    ← Hyprland primary state or offline (retained)
#
{
  osConfig,
  pkgs,
  lib,
  ...
}: let
  cfg = osConfig.modules.haPresence or {enable = false;};
  enabled = cfg.enable && pkgs.stdenv.isLinux;
  passPath = osConfig.age.secrets.ha-mqtt-pass.path or "";

  topicBase = "homeassistant/sensor/${cfg.deviceId or "presence"}";
  stateTopic = "${topicBase}/state";
  configTopic = "${topicBase}/config";

  # mosquitto_pub arguments common to every publish. Authentication is loaded
  # from a private options file so the password never appears in argv.
  mqttPub = pkgs.writeShellApplication {
    name = "ha-presence-mqtt-pub";
    runtimeInputs = [pkgs.mosquitto];
    text = ''
      topic="''${1:?usage: ha-presence-mqtt-pub <topic> <payload>}"
      payload="''${2:?usage: ha-presence-mqtt-pub <topic> <payload>}"
      pass_file="${passPath}"
      auth_file="$(mktemp)"
      trap 'rm -f "$auth_file"' EXIT
      if [ ! -r "$pass_file" ]; then
        echo "ha-presence: cannot read $pass_file" >&2
        exit 1
      fi

      # mosquitto 2.1 supports authentication options in a private config file,
      # keeping the password out of the process command line.
      {
        printf '%s %s\n' '-u' "${cfg.username or ""}"
        printf '%s ' '-P'
        cat "$pass_file"
        printf '\n'
      } >"$auth_file"

      mosquitto_pub \
        -o "$auth_file" \
        -h "${cfg.brokerHost or ""}" \
        -p "${toString (cfg.brokerPort or 1883)}" \
        -t "$topic" \
        -m "$payload" \
        -r \
        -q 1 \
        --keepalive 10
    '';
  };

  ha-presence-update = pkgs.writeShellApplication {
    name = "ha-presence-update";
    runtimeInputs = [mqttPub];
    text = ''
      state="''${1:?usage: ha-presence-update <state>}"
      ha-presence-mqtt-pub "${stateTopic}" "$state"
    '';
  };

  # HA MQTT discovery payload — registers the sensor on first publish.
  # Sent retained so HA picks it up whenever it (re)connects to the broker.
  discoveryPayload = builtins.toJSON {
    name = "${cfg.deviceId or "presence"}";
    unique_id = "${cfg.deviceId or "presence"}";
    state_topic = stateTopic;
    icon = "mdi:account";
    device = {
      identifiers = [(cfg.deviceId or "presence")];
      name = cfg.deviceId or "presence";
      manufacturer = "ha-presence";
    };
  };

  ha-presence-discover = pkgs.writeShellApplication {
    name = "ha-presence-discover";
    runtimeInputs = [mqttPub];
    text = ''
      ha-presence-mqtt-pub "${configTopic}" '${discoveryPayload}'
    '';
  };

  updateBin = "${ha-presence-update}/bin/ha-presence-update";
  discoverBin = "${ha-presence-discover}/bin/ha-presence-discover";
  hyprctl = "${osConfig.programs.hyprland.package}/bin/hyprctl";
  uwsm = lib.getExe pkgs.uwsm;
  hyprState = name: enabled: "${uwsm} app -- ${hyprctl} eval 'Juicy.state.set(\"${name}\", ${
    if enabled
    then "true"
    else "false"
  })'";
in {
  config = lib.mkIf enabled {
    assertions = [
      {
        assertion = cfg.brokerHost != "";
        message = "modules.haPresence.brokerHost must be set when presence publishing is enabled";
      }
      {
        assertion = cfg.username != "";
        message = "modules.haPresence.username must be set when presence publishing is enabled";
      }
    ];

    home.packages = [ha-presence-update ha-presence-discover mqttPub];

    programs.noctalia.settings.hooks = {
      started = [
        discoverBin
        "${uwsm} app -- ${hyprctl} eval 'Juicy.state.set(\"idle\", false)'"
      ];
      session_locked = [(hyprState "locked" true)];
      session_unlocked = [
        (hyprState "locked" false)
        (hyprState "idle" false)
      ];
      logging_out = ["${updateBin} offline"];
      rebooting = ["${updateBin} offline"];
      shutting_down = ["${updateBin} offline"];
    };

    programs.noctalia.settings.idle.behavior = {
      "ha-presence-idle" = {
        enabled = true;
        timeout = cfg.idleTimeout;
        action = "command";
        command = hyprState "idle" true;
        resume_command = hyprState "idle" false;
      };

      "ha-presence-sleep" = {
        enabled = true;
        timeout = cfg.sleepTimeout;
        action = "command";
        command = hyprState "idle" true;
        resume_command = hyprState "idle" false;
      };
    };

    # uwsm runs hyprland under wayland-wm@hyprland.service; ExecStopPost fires
    # on both clean exit and crash. Publish `offline` retained — HA will see
    # it next time it polls and on every reconnect.
    #
    # NOTE: a true MQTT LWT would catch hard power loss too, but that requires
    # a long-lived client. Acceptable trade-off for now; hyprland-shutdown
    # paths cover the normal cases.
    xdg.configFile."systemd/user/wayland-wm@hyprland.service.d/ha-presence.conf".text = ''
      [Service]
      ExecStopPost=${updateBin} offline
    '';
  };
}
