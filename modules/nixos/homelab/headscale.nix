# Headscale — self-hosted Tailscale coordination server.
# Runs on zues, exposed externally via cloudflared at ts.nixlab.au.
# All Tailscale clients point --login-server at that URL.
{
  config,
  lib,
  ...
}: let
  enabled = config.modules.homelab.headscale.enable;
  inherit (config.modules) ports;
in {
  config = lib.mkIf enabled {
    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      port = ports.headscale;

      settings = {
        server_url = "https://ts.nixlab.au";

        prefixes = {
          v4 = "100.64.0.0/10";
          v6 = "fd7a:115c:a1e0::/48";
        };

        database = {
          type = "sqlite";
          sqlite.path = "/var/lib/headscale/db.sqlite";
        };

        # Use Tailscale's public DERP relay map — no self-hosted DERP needed.
        derp = {
          server.enabled = false;
          urls = ["https://controlplane.tailscale.com/derpmap/default"];
          auto_update_enabled = true;
          update_frequency = "24h";
        };

        dns = {
          magic_dns = true;
          # Nodes resolve as <name>.<user>.ts — keep it short.
          base_domain = "ts";
          nameservers.global = ["192.168.1.99"];
        };

        log.level = "warn";
        disable_check_updates = true;
      };
    };

    # Nginx proxy — headscale needs WebSocket + long-lived connections for streaming.
    services.nginx.virtualHosts."ts.nixlab.au" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString ports.headscale}";
        # proxyWebsockets = true;
        extraConfig = ''
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_read_timeout 86400s;
        '';
      };
    };
  };
}
