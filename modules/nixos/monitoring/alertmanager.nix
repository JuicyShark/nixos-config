# Prometheus Alertmanager retains and groups alerts locally. Email delivery is
# owned by the independent, daily-rate-limited diagnostics service on Leo.
{
  config,
  lib,
  ...
}: let
  enabled = config.modules.monitoring.enable;
  inherit (config.modules) ports;
in {
  config = lib.mkIf enabled {
    services.prometheus = {
      alertmanagers = [
        {
          static_configs = [
            {
              targets = ["127.0.0.1:${toString ports.alertmanager}"];
            }
          ];
        }
      ];

      alertmanager = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = ports.alertmanager;
        checkConfig = true;
        webExternalUrl = "http://alertmanager.home.arpa";
        configuration = {
          route = {
            receiver = "local";
            group_by = [
              "alertname"
              "instance"
            ];
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "12h";
          };
          receivers = [
            {
              # Alertmanager remains useful for grouping, inhibition, and its
              # API. The diagnostics mailer polls Prometheus and owns the only
              # outbound notification path.
              name = "local";
            }
          ];
          inhibit_rules = [
            {
              source_matchers = ["severity=\"critical\""];
              target_matchers = ["severity=\"warning\""];
              equal = [
                "alertname"
                "instance"
              ];
            }
          ];
        };
      };
    };

    services.nginx.virtualHosts."alertmanager.home.arpa" = {
      locations."/".proxyPass = "http://127.0.0.1:${toString ports.alertmanager}";
      extraConfig = ''
        allow 192.168.1.0/24;
        allow 100.64.0.0/10;
        deny all;
      '';
    };
  };
}
