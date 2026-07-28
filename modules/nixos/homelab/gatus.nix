# Gatus — declarative uptime monitor and status page.
{
  config,
  lib,
  pkgs,
  ...
}: let
  enabled = config.modules.homelab.gatus.enable;
  cfg = config.modules.homelab.gatus;
  inherit (config.modules) ports;

  format = pkgs.formats.yaml {};
in {
  options.modules.homelab.gatus = {
    settings = lib.mkOption {
      inherit (format) type;
      default = {};
      description = "Gatus configuration, serialised to YAML. See https://gatus.io/docs.";
    };
  };

  config = lib.mkIf enabled {
    services.gatus = {
      enable = true;
      openFirewall = false;
      inherit (cfg) settings;
    };

    services.nginx.virtualHosts."status.home.arpa".locations."/" = {
      proxyPass = "http://127.0.0.1:${toString ports.gatus}";
    };
  };
}
