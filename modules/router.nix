{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    modules.router = {
      enable = lib.mkEnableOption "Enable Router Config";
      networking = {
        ipv4 = lib.mkOption {
          type = lib.types.string;
          default = lib.mkForce "192.168.1.99";
        };
      };
    };
    modules.server = {
      enable = lib.mkEnableOption "Enable Server Config";
      cloudflare = lib.mkEnableOption "Enable Cloudflare tunnel";
      media = lib.mkEnableOption "Enable Media Server";
    };

    modules.switch = {
      enable = lib.mkEnableOption "Enable Switch Config";
    };
  };

  config = {

  };
}
