# Home-side wiring for HA presence reporting via MQTT. Hyprland and Noctalia
# write immediate source facts; a persistent user service qualifies and
# stabilizes them before publishing.
#
# Topics:
#   homeassistant/sensor/<deviceId>/config   ← discovery (retained)
#   homeassistant/sensor/<deviceId>/state    ← stable primary state (retained)
#   homeassistant/sensor/<deviceId>/availability ← persistent-client LWT
#
{
  osConfig,
  pkgs,
  lib,
  ...
}: let
  cfg = osConfig.modules.haPresence or {enable = false;};
  enabled = cfg.enable && pkgs.stdenv.hostPlatform.isLinux;
  passPath = osConfig.age.secrets.ha-mqtt-pass.path or "";

  topicBase = "homeassistant/sensor/${cfg.deviceId or "presence"}";
  stateTopic = "${topicBase}/state";
  configTopic = "${topicBase}/config";
  availabilityTopic = "${topicBase}/availability";

  # HA MQTT discovery payload — registers the sensor on first publish.
  # Sent retained so HA picks it up whenever it (re)connects to the broker.
  discoveryPayload = builtins.toJSON {
    name = "${cfg.deviceId or "presence"}";
    unique_id = "${cfg.deviceId or "presence"}";
    state_topic = stateTopic;
    availability_topic = availabilityTopic;
    payload_available = "online";
    payload_not_available = "offline";
    icon = "mdi:account";
    device = {
      identifiers = [(cfg.deviceId or "presence")];
      name = cfg.deviceId or "presence";
      manufacturer = "ha-presence";
    };
  };

  python = pkgs.python3.withPackages (pythonPackages: [pythonPackages.paho-mqtt]);
  haPresence = pkgs.writeShellApplication {
    name = "ha-presence";
    runtimeInputs = [python];
    text = ''
      exec python ${./ha-presence.py} "$@"
    '';
  };
  mqttPublisher = import ../../lib/ha-mqtt-publisher.nix {
    inherit pkgs;
    host = cfg.brokerHost or "";
    username = cfg.username or "";
    passwordFile = passPath;
    port = cfg.brokerPort;
  };

  controllerConfig = pkgs.writeText "ha-presence-controller.json" (builtins.toJSON {
    host = cfg.brokerHost or "";
    port = cfg.brokerPort;
    username = cfg.username or "";
    password_file = passPath;
    device_id = cfg.deviceId or "presence";
    state_topic = stateTopic;
    config_topic = configTopic;
    availability_topic = availabilityTopic;
    discovery_payload = discoveryPayload;
    stability_seconds = cfg.stabilitySeconds;
    gaming_seconds = cfg.gamingQualificationSeconds;
    priority = [
      "locked"
      "remote-streaming"
      "streaming"
      "screen-recording"
      "gaming"
    ];
  });

  presenceBin = lib.getExe haPresence;
  sourceState = source: name: active: "${presenceBin} source ${source} ${name} ${
    if active
    then "true"
    else "false"
  }";
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

    home.packages = [haPresence mqttPublisher];

    programs.noctalia.settings.hooks = {
      session_locked = [(sourceState "noctalia" "locked" true)];
      session_unlocked = [(sourceState "noctalia" "locked" false)];
    };

    systemd.user.services.ha-presence-controller = {
      Unit = {
        Description = "Stable Home Assistant presence controller";
        After = ["graphical-session.target" "network-online.target"];
        Wants = ["network-online.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${presenceBin} daemon --config ${controllerConfig}";
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0077";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
