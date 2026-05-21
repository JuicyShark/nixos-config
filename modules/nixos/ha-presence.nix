# Centralised presence reporting to Home Assistant via MQTT.
#
# Pipeline:
#   active   ← hyprland.start (Lua) and hypridle on-resume
#   idle     ← hypridle (idleTimeout)
#   sleep    ← hypridle (sleepTimeout, long-idle)
#   offline  ← systemd ExecStopPost on uwsm wayland-wm@hyprland.service
#
# Publishes to the HA Mosquitto add-on. Uses MQTT discovery so HA auto-creates
# the sensor on first publish. State is retained — survives HA / broker
# restarts. Credentials come from secrets/ha-mqtt-pass.age (read at runtime
# so they never appear in process arguments).
{
  config,
  lib,
  ...
}: let
  cfg = config.modules.haPresence;
in {
  options.modules.haPresence = {
    enable = lib.mkEnableOption "Home Assistant presence reporting (MQTT)";

    deviceId = lib.mkOption {
      type = lib.types.str;
      default = "${config.modules.system.hostName}_presence";
      description = "MQTT device/object id; used in topic and HA entity_id.";
    };

    brokerHost = lib.mkOption {
      type = lib.types.str;
      default = config.modules.network.hosts.homeAssistant;
      description = "MQTT broker hostname/IP (HA Mosquitto add-on).";
    };

    brokerPort = lib.mkOption {
      type = lib.types.port;
      default = config.modules.ports.mqtt;
      description = "MQTT broker port.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = "juicy";
      description = "MQTT username.";
    };

    idleTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 300;
      description = "Seconds of inactivity before reporting `idle` (default 5min).";
    };

    sleepTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1800;
      description = "Seconds of inactivity before reporting `sleep` (default 30min).";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      ha-mqtt-pass = {
        file = ../../secrets/ha-mqtt-pass.age;
        owner = config.modules.system.username;
        mode = "0400";
      };
    };
  };
}
