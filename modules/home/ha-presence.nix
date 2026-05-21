# Home-side wiring for HA presence reporting via MQTT. Reads
# osConfig.modules.haPresence and provides:
#   - ha-presence-update <state>  on $PATH  (publishes retained MQTT message)
#   - ha-presence-discover        publishes HA discovery config (retained, once)
#   - hypridle listeners for idle/sleep with on-resume → active
#   - systemd user drop-in for wayland-wm@hyprland.service ExecStopPost → offline
#
# Topics:
#   homeassistant/sensor/<deviceId>/config   ← discovery (retained)
#   homeassistant/sensor/<deviceId>/state    ← active|idle|sleep|offline (retained)
#
# The hyprland.start → discover + active transition lives in
# modules/home/hyprland/lua.nix (gated on hasHaPresence).
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

  # mosquitto_pub args common to every publish. Password read from file via -P
  # would leak in argv; mosquitto_pub supports --pw-file via env, but the
  # cleanest portable form is reading into a variable in the wrapper script.
  mqttPub = pkgs.writeShellApplication {
    name = "ha-presence-mqtt-pub";
    runtimeInputs = [pkgs.mosquitto];
    text = ''
      topic="''${1:?usage: ha-presence-mqtt-pub <topic> <payload>}"
      payload="''${2:?usage: ha-presence-mqtt-pub <topic> <payload>}"
      pass_file="${passPath}"
      if [ ! -r "$pass_file" ]; then
        echo "ha-presence: cannot read $pass_file" >&2
        exit 1
      fi
      pass=$(cat "$pass_file")
      # Password ends up in argv briefly. Acceptable on single-user desktop
      # (proc cmdline is mode 0400 to the owning user); mosquitto_pub has no
      # password-file flag.
      mosquitto_pub \
        -h "${cfg.brokerHost or ""}" \
        -p "${toString (cfg.brokerPort or 1883)}" \
        -u "${cfg.username or ""}" \
        -P "$pass" \
        -t "$topic" \
        -m "$payload" \
        -r \
        -q 1 \
        --keepalive 10 || true
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
in {
  config = lib.mkIf enabled {
    home.packages = [ha-presence-update ha-presence-discover mqttPub];

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          ignore_dbus_inhibit = false;
          ignore_systemd_inhibit = false;
        };
        listener = [
          {
            timeout = cfg.idleTimeout;
            on-timeout = "${updateBin} idle";
            on-resume = "${updateBin} active";
          }
          {
            timeout = cfg.sleepTimeout;
            on-timeout = "${updateBin} sleep";
            on-resume = "${updateBin} active";
          }
        ];
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
