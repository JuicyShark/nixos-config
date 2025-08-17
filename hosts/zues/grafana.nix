{ config, ... }:
{
  services = {
    grafana = {
      enable = true;
      openFirewall = true;

      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3007;
        };
      };

      provision = {
        enable = true;

        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://localhost:3000";
          }
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://localhost:3005";
          }
        ];
      };
    };

    loki = {
      enable = true;

      configuration = {
        auth_enabled = false;

        server = {
          http_listen_port = 3005;
          grpc_listen_port = 0;
        };

        common = {
          instance_addr = "0.0.0.0";
          path_prefix = "/tmp/loki";

          storage = {
            filesystem = {
              chunks_directory = "/tmp/loki/chunks";
              rules_directory = "/tmp/loki/rules";
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
            url = "http://localhost:3005/api/v1/push";
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
      port = 3000;

      scrapeConfigs = [
        {
          job_name = "unbound";
          static_configs = [
            {
              targets = [ "zues.lan:9167" ];
            }
          ];
        }
        {
          job_name = "lidarr";
          static_configs = [
            {
              targets = [ "leo.lan:9709" ];
            }
          ];
        }

        {
          job_name = "prowlarr";
          static_configs = [
            {
              targets = [ "leo.lan:9710" ];
            }
          ];
        }

        {
          job_name = "radarr";
          static_configs = [
            {
              targets = [ "leo.lan:9711" ];
            }
          ];
        }

        {
          job_name = "smartctl";
          static_configs = [
            {
              targets = [ "leo.lan:9633" ];
              labels.instance = "leo";
            }
          ];
        }

        {
          job_name = "sonarr";
          static_configs = [
            {
              targets = [ "leo.lan:9712" ];
            }
          ];
        }

        {
          job_name = "node";
          static_configs = [
            {
              targets = [ "leo.lan:3021" ];
              labels.instance = "leo";
            }
            {
              targets = [ "zues.lan:3021" ];
              labels.instance = "zues";
            }
          ];
        }
        {
          job_name = "ollama";
          static_configs = [ { targets = [ "leo.lan:11434" ]; } ];
        }
        {
          job_name = "open-webui";
          static_configs = [ { targets = [ "leo.lan:11111" ]; } ];
        }
      ];
    };
  };
}
