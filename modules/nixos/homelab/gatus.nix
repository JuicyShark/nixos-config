# Gatus — declarative uptime monitor and status page.
# Config is generated from Nix attrs and written to the Nix store.
# https://gatus.io/
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
  configFile = format.generate "gatus.yaml" cfg.settings;
in {
  options.modules.homelab.gatus = {
    settings = lib.mkOption {
      inherit (format) type;
      default = {};
      description = "Gatus configuration, serialised to YAML. See https://gatus.io/docs.";
    };
  };

  config = lib.mkIf enabled {
    systemd.services.gatus = {
      description = "Gatus status monitor";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      environment.GATUS_CONFIG_PATH = "${configFile}";
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        StateDirectory = "gatus";
        ExecStart = "${pkgs.gatus}/bin/gatus";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = ["/var/lib/gatus"];
      };
    };

    services.nginx.virtualHosts."status.home.arpa".locations."/" = {
      proxyPass = "http://127.0.0.1:${toString ports.gatus}";
    };
  };
}
