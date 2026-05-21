# Uptime Kuma — service status monitor.
# Exposed internally at status.home.arpa and externally at status.nixlab.au
# so family can self-check whether the server is down.
{
  config,
  lib,
  ...
}: let
  inherit (config.modules) ports;
in {
  config = lib.mkIf config.modules.homelab.uptimeKuma.enable {
    services.uptime-kuma = {
      enable = true;
      settings = {
        HOST = "127.0.0.1";
        PORT = toString ports.uptimeKuma;
      };
    };

    services.nginx.virtualHosts."status.home.arpa".locations."/" = {
      proxyPass = "http://127.0.0.1:${toString ports.uptimeKuma}";
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
      '';
    };
  };
}
