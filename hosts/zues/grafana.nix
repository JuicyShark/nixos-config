{ config, ... }:
let
  promCfg = config.services.prometheus.exporters;
  ports = {
    grafana = 3007;
    prometheus = 3000;
    loki = 3005;
    node = promCfg.node.port;
  };
in
{
  services = {

    opentelemetry-collector = {
      enable = true;
      settings = {
        receivers.otlp.protocols.grpc.endpoint = "0.0.0.0:4317";
        exporters.prometheus = {
          endpoint = "0.0.0.0:9464";
        };
        service.pipelines.metrics = {
          receivers = [ "otlp" ];
          exporters = [ "prometheus" ];
        };
      };
    };
    grafana = {
      enable = true;
      openFirewall = true;

      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = ports.grafana;
        };
      };

      provision = {
        enable = true;

        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://zues.lan:${toString ports.prometheus}";
          }
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://zues.lan:${toString ports.loki}";
          }
        ];
      };
    };

    loki = {
      enable = true;

      configuration = {
        auth_enabled = false;

        server = {
          http_listen_port = ports.loki;
          http_listen_address = "0.0.0.0";
        };

        common = {
          instance_addr = "0.0.0.0";
          path_prefix = "/var/lib/loki";

          storage = {
            filesystem = {
              chunks_directory = "/var/lib/loki/chunks";
              rules_directory = "/var/lib/loki/rules";
            };
          };

          replication_factor = 1;

          ring = {
            kvstore = {
              store = "inmemory";
            };
          };
        };

        frontend = {
          max_outstanding_per_tenant = 2048;
        };

        pattern_ingester = {
          enabled = true;
        };
        ingester = {
          lifecycler = {
            ring = {
              kvstore.store = "inmemory";
            };
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
          ingestion_rate_mb = 50000;
          ingestion_burst_size_mb = 50000;
          volume_enabled = true;
        };

        query_range = {
          results_cache = {
            cache = {
              embedded_cache = {
                enabled = true;
                max_size_mb = 100;
              };
            };
          };
        };

        schema_config = {
          configs = [
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
        };

        analytics = {
          reporting_enabled = false;
        };
      };
    };

    promtail = {
      enable = true;

      configuration = {
        server = {
          http_listen_port = 3031;
          grpc_listen_port = 0;
        };

        positions = {
          filename = "/tmp/positions.yaml";
        };

        clients = [
          {
            url = "http://zues.lan:${toString ports.loki}/api/v1/push";
          }
        ];

        scrape_configs = [
          {
            job_name = "journal";

            journal = {
              max_age = "12h";

              labels = {
                job = "systemd-journal";
                host = config.networking.hostName;
              };
            };

            relabel_configs = [
              {
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }
              {
                source_labels = [ "__journal__systemd_user_unit" ];
                target_label = "user_unit";
              }
            ];
          }
        ];
      };
    };

    prometheus = {
      enable = true;
      globalConfig.scrape_interval = "10s";
      port = ports.prometheus;

      scrapeConfigs = [

        {
          job_name = "open-webui";
          static_configs = [
            {
              targets = [
                (toString config.services.opentelemetry-collector.settings.exporters.prometheus.endpoint)
              ];
              labels.service = "open-webui";

            }
          ];
        }

        {
          job_name = "unbound";
          static_configs = [
            {
              targets = [ "zues.lan:${toString promCfg.unbound.port}" ];
            }
          ];
        }
        {
          job_name = "vaultwarden";
          static_configs = [
            {
              targets = [ "zues.lan:8521" ];
            }
          ];
        }

        {
          job_name = "bazarr";
          static_configs = [
            {
              targets = [ "leo.lan:${toString promCfg.exportarr-bazarr.port}" ];
            }
          ];
        }

        {
          job_name = "lidarr";
          static_configs = [
            {
              targets = [ "leo.lan:${toString promCfg.exportarr-lidarr.port}" ];
            }
          ];
        }

        {
          job_name = "prowlarr";
          static_configs = [
            {
              targets = [ "leo.lan:${toString promCfg.exportarr-prowlarr.port}" ];
            }
          ];
        }

        {
          job_name = "radarr";
          static_configs = [
            {
              targets = [ "leo.lan:${toString promCfg.exportarr-radarr.port}" ];
            }
          ];
        }
        {
          job_name = "sonarr";
          static_configs = [
            {
              targets = [ "leo.lan:${toString promCfg.exportarr-sonarr.port}" ];
            }
          ];
        }

        {
          job_name = "smartctl";
          static_configs = [
            {
              targets = [ "leo.lan:${toString promCfg.smartctl.port}" ];
              labels.instance = "leo";
            }
            {
              targets = [ "zues.lan:${toString promCfg.smartctl.port}" ];
              labels.instance = "zues";
            }
          ];
        }

        {
          job_name = "node";
          static_configs = [
            {
              targets = [ "leo.lan:${toString ports.node}" ];
              labels.instance = "leo";
            }
            {
              targets = [ "zues.lan:${toString ports.node}" ];
              labels.instance = "zues";
            }
          ];
        }
        {
          job_name = "deluge";
          static_configs = [
            { targets = [ "leo.lan:${toString promCfg.deluge.port}" ]; }
          ];
        }
      ];
    };
  };
}
