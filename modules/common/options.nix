{lib, ...}: {
  options.modules = {
    profile = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "juicy";
        description = "Primary user managed by this configuration.";
      };

      homeDirectory = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Primary user's home directory; defaults by platform when unset.";
      };

      homeStateVersion = lib.mkOption {
        type = lib.types.str;
        default = "25.11";
        description = "Home Manager state version for the primary user.";
      };

      hashedPasswordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional age-managed hashed password file for the primary user.";
      };
    };

    system = {
      keyboard.zsa = lib.mkEnableOption "ZSA keyboard firmware (keymapp + kontroll)";
      highMemory.enable = lib.mkEnableOption "high-RAM optimizations (tmpfs for /tmp)";

      mullvad.enable = lib.mkEnableOption "Mullvad VPN client";
      openSrb2Port = lib.mkEnableOption "SRB2 multiplayer firewall port (UDP 5029)";
      openDevPort = lib.mkEnableOption "development server firewall port (TCP 3000)";
    };

    haPresence = {
      enable = lib.mkEnableOption "Home Assistant presence publishing over MQTT";

      deviceId = lib.mkOption {
        type = lib.types.str;
        default = "presence";
        description = "Home Assistant MQTT discovery device and sensor id.";
      };

      brokerHost = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "MQTT broker hostname or address.";
      };

      brokerPort = lib.mkOption {
        type = lib.types.port;
        default = 1883;
        description = "MQTT broker port.";
      };

      username = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "MQTT username used by the presence publisher.";
      };

      idleTimeout = lib.mkOption {
        type = lib.types.ints.positive;
        default = 300;
        description = "Seconds of idle time before publishing the idle state.";
      };

      sleepTimeout = lib.mkOption {
        type = lib.types.ints.positive;
        default = 900;
        description = "Seconds of idle time before publishing the sleep state.";
      };
    };
  };
}
