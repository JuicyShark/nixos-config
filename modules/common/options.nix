{lib, ...}: {
  options.modules = {
    profile = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "juicy";
        description = "Primary user managed by this configuration.";
      };

      flakePath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Local checkout used by FLAKE and nh; leave unset when no checkout lives on the host.";
      };

      homeStateVersion = lib.mkOption {
        type = lib.types.str;
        default = "25.11";
        description = "Home Manager state version for the primary user.";
      };
    };

    system = {
      media.enable = lib.mkEnableOption "shared media user and group";
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
        default = "hass.home.arpa";
        description = "MQTT broker hostname or address.";
      };

      brokerPort = lib.mkOption {
        type = lib.types.port;
        default = 1883;
        description = "MQTT port shared by the presence controller and command publishers.";
      };

      username = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "MQTT username used by the presence publisher.";
      };

      stabilitySeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 30;
        description = "Seconds a selected presence state must remain unchanged before publication.";
      };

      gamingQualificationSeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 10 * 60;
        description = "Seconds gaming must remain active before it can become the presence state.";
      };
    };
  };
}
