# Loki log aggregation + Alloy log shipping (replaces promtail).
{
  config,
  lib,
  ...
}: let
  homelabMonitoring = config.modules.monitoring.enable;
  homelabHostMonitoring = config.modules.monitoring.host.enable;
  inherit (config.modules) ports;
  lokiUrl = "http://192.168.1.99:${toString ports.loki}/loki/api/v1/push";
  hostname = config.networking.hostName;
in {
  config = {
    services = {
      # Grafana Alloy replaces promtail for journal log shipping
      alloy = {
        enable = homelabHostMonitoring;
        extraFlags = [
          "--server.http.listen-addr=0.0.0.0:${toString ports.alloy}"
          "--disable-reporting"
        ];
      };

      loki = {
        enable = homelabMonitoring;
        configuration = {
          auth_enabled = false;
          server = {
            http_listen_port = ports.loki;
            http_listen_address = "0.0.0.0";
          };
          common = {
            path_prefix = "/var/lib/loki";
            storage.filesystem = {
              chunks_directory = "/var/lib/loki/chunks";
              rules_directory = "/var/lib/loki/rules";
            };
            replication_factor = 1;
            ring.kvstore.store = "inmemory";
          };
          frontend.max_outstanding_per_tenant = 2048;
          pattern_ingester.enabled = true;
          ingester = {
            lifecycler = {
              ring.kvstore.store = "inmemory";
              final_sleep = "0s";
            };
            chunk_idle_period = "5m";
            max_chunk_age = "1h";
            chunk_retain_period = "30s";
            wal = {
              enabled = true;
              dir = "/var/lib/loki/wal";
            };
          };
          limits_config = {
            max_global_streams_per_user = 0;
            ingestion_rate_mb = 50;
            ingestion_burst_size_mb = 100;
            volume_enabled = true;
            retention_period = "744h"; # 31 days
          };

          compactor = {
            working_directory = "/var/lib/loki/compactor";
            compaction_interval = "10m";
            retention_enabled = true;
            retention_delete_delay = "2h";
            delete_request_store = "filesystem";
          };
          query_range.results_cache.cache.embedded_cache = {
            enabled = true;
            max_size_mb = 100;
          };
          schema_config.configs = [
            {
              from = "2020-10-24";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
          analytics.reporting_enabled = false;
        };
      };

      nginx.virtualHosts = lib.mkIf config.services.loki.enable {
        "loki.home.arpa" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString ports.loki}";
          };
          extraConfig = ''
            allow 192.168.1.0/24;
            allow 100.64.0.0/10;
            deny all;
          '';
        };
      };
    };

    environment.etc."alloy/config.alloy" = lib.mkIf config.services.alloy.enable {
      text = ''
        loki.relabel "journal" {
          forward_to = []

          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
          }
          rule {
            source_labels = ["__journal__systemd_user_unit"]
            target_label  = "user_unit"
          }
        }

        loki.source.journal "systemd" {
          max_age       = "12h"
          relabel_rules = loki.relabel.journal.rules
          forward_to    = [loki.write.default.receiver]
          labels        = {
            job      = "systemd-journal",
            host     = "${hostname}",
            instance = "${hostname}",
          }
        }

        loki.write "default" {
          endpoint {
            url = "${lokiUrl}"
          }
        }
      '';
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = lib.mkIf config.services.alloy.enable [ports.alloy];
  };
}
