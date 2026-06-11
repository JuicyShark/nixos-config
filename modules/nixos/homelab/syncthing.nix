# Syncthing — continuous file sync node for the homelab.
# GUI proxied at syncthing.home.arpa. Devices and folders are
# configured through the web UI on first run.
{
  config,
  lib,
  ...
}: let
  enabled = config.modules.homelab.syncthing.enable;
  inherit (config.modules) ports;
in {
  config = lib.mkIf enabled {
    services.syncthing = {
      enable = true;
      user = "juicy";
      dataDir = "/home/juicy";
      guiAddress = "127.0.0.1:${toString ports.syncthing}";
      openDefaultPorts = true;
    };

    services.nginx.virtualHosts."syncthing.home.arpa".locations."/" = {
      proxyPass = "http://127.0.0.1:${toString ports.syncthing}";
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
      '';
    };
  };
}
