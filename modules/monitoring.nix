{
  config,
  lib,
  pkgs,
  ...
}:
let
  hostCfg = config.modules;
  promCfg = config.services.prometheus.exporters;
  ports = {
    grafana = 3000;
    prometheus = 9090;
    promtail = 9080;
    loki = 3100;
    node = 3021;
    unboundExporter = 9167;
    prowlarrExporter = 9710;
    sonarrExporter = 9712;
    radarrExporter = 9711;
    lidarrExporter = 9709;
    bazarrExporter = 9708;
    delugeExporter = 9720;
  };

in
{
  options.modules.homelab = {
    hostMonitoring = lib.mkEnableOption "Host Device Monitoring";
    monitoring = lib.mkEnableOption "Monitoring via Prometheus";
  };

  config = {
    age.secrets = {

      prowlarr-api = lib.mkIf config.services.prowlarr.enable {
        file = ../secrets/prowlarr-api.age;
      };
      radarr-api = lib.mkIf config.services.radarr.enable {
        file = ../secrets/radarr-api.age;
      };
      sonarr-api = lib.mkIf config.services.sonarr.enable {
        file = ../secrets/sonarr-api.age;
      };
      lidarr-api = lib.mkIf config.services.lidarr.enable {
        file = ../secrets/lidarr-api.age;
      };

      bazarr-api = lib.mkIf config.services.bazarr.enable {
        file = ../secrets/bazarr-api.age;
      };
      deluge-pass = lib.mkIf config.services.deluge.enable {
        file = ../secrets/deluge-pass.age;
        owner = "deluge-exporter";
      };
    };

    services = {
      # individual exporters
      prometheus.exporters = {
        deluge = {
          enable = lib.mkIf config.services.deluge.enable true;
          #delugePassword = "deluge";
          delugeUser = "juicy";
          delugePasswordFile = config.age.secrets.deluge-pass.path;
          delugePort = config.services.deluge.config.daemon_port;
          openFirewall = true;
          port = ports.delugeExporter;
        };
        exportarr-bazarr = {
          enable = lib.mkIf config.services.bazarr.enable true;
          apiKeyFile = config.age.secrets.bazarr-api.path;
          port = ports.bazarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://leo.lan:${toString config.services.bazarr.listenPort}";
          openFirewall = true;
          environment = {
            ENABLE_ADDITIONAL_METRICS = "true";
            PROWLARR__BACKFILL = "true";
          };
        };

        exportarr-lidarr = {
          enable = lib.mkIf config.services.lidarr.enable true;
          apiKeyFile = config.age.secrets.lidarr-api.path;
          port = ports.lidarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://leo.lan:${toString config.services.lidarr.settings.server.port}";
          openFirewall = true;
          environment = {
            ENABLE_ADDITIONAL_METRICS = "true";
            PROWLARR__BACKFILL = "true";
          };
        };

        exportarr-prowlarr = {
          enable = lib.mkIf config.services.prowlarr.enable true;
          apiKeyFile = config.age.secrets.prowlarr-api.path;
          port = ports.prowlarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://leo.lan:${toString config.services.prowlarr.settings.server.port}";
          openFirewall = true;
          environment = {
            ENABLE_ADDITIONAL_METRICS = "true";
            PROWLARR__BACKFILL = "true";
          };

        };

        exportarr-radarr = {
          enable = lib.mkIf config.services.radarr.enable true;
          apiKeyFile = config.age.secrets.radarr-api.path;
          port = ports.radarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://leo.lan:${toString config.services.radarr.settings.server.port}";
          openFirewall = true;
          environment = {
            ENABLE_ADDITIONAL_METRICS = "true";
            PROWLARR__BACKFILL = "true";
          };

        };

        exportarr-sonarr = {
          enable = lib.mkIf config.services.sonarr.enable true;
          apiKeyFile = config.age.secrets.sonarr-api.path;
          port = ports.sonarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://leo.lan:${toString config.services.sonarr.settings.server.port}";
          openFirewall = true;
          environment = {
            ENABLE_ADDITIONAL_METRICS = "true";
            PROWLARR__BACKFILL = "true";
          };

        };

        smartctl = {
          enable = lib.mkIf hostCfg.homelab.nas true;
          openFirewall = true;
          maxInterval = "5m";
          devices = [
            "/dev/nvme0"
            "/dev/nvme1"
            "/dev/sdd"
            "/dev/sde"
          ];
        };

        node = {
          enable = lib.mkIf hostCfg.homelab.hostMonitoring true;
          enabledCollectors = [ "systemd" ];
          openFirewall = true;

          extraFlags = [
            "--collector.ethtool"
            "--collector.softirqs"
            "--collector.tcpstat"
            "--collector.wifi"
            "--collector.cpu"

            "--collector.interrupts"
            "--collector.softnet"
            "--collector.hwmon"
          ];

          port = ports.node;
        };
      };

      promtail = {
        enable = lib.mkIf hostCfg.homelab.hostMonitoring true;

        configuration = {
          server = {
            http_listen_port = ports.promtail;
            grpc_listen_port = 0;
          };

          positions = {
            filename = "/tmp/positions.yaml";
          };

          clients = [
            {
              url = "http://192.168.1.99:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
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

      #central monitoring
      /*
        opentelemetry-collector = {
          enable = lib.mkIf hostCfg.homelab.monitoring true;
          settings = {
            receivers.otlp.protocols.grpc.endpoint = "zues.lan:4317";
            receivers.otlp.protocols.http.endpoint = "zues.lan:4318";
            processors = {
              batch = { };
              memory_limiter = {
                check_interval = "15s";
                limit_mib = 512; # tune to box size
                spike_limit_mib = 128;
              };
            };
            exporters.prometheus = {
              endpoint = "zues.lan:9464";
            };
            service.pipelines.metrics = {
              receivers = [ "otlp" ];
              processors = [
                "memory_limiter"
                "batch"
              ];
              exporters = [ "prometheus" ];
            };
          };
        };
      */

      grafana = {
        enable = lib.mkIf hostCfg.homelab.monitoring true;
        openFirewall = true;

        settings = {
          server = {
            http_addr = "192.168.1.99";
            http_port = ports.grafana;
          };
        };

        provision = {
          enable = lib.mkIf config.services.grafana.enable true;

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
        enable = lib.mkIf hostCfg.homelab.monitoring true;

        configuration = {
          auth_enabled = false;

          server = {
            http_listen_port = ports.loki;
            http_listen_address = "192.168.1.99";
          };

          common = {
            #instance_addr = "zues.lan";
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
            ingestion_rate_mb = 50;
            ingestion_burst_size_mb = 100;
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

      prometheus = {
        enable = lib.mkIf hostCfg.homelab.monitoring true;
        globalConfig.scrape_interval = "60s";
        port = ports.prometheus;

        scrapeConfigs = [

          /*
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
          */

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
            scrape_interval = "120s";
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
  };
}
