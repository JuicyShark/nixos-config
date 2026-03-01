{
  config,
  lib,
  pkgs,
  ...
}:
let
  hasRole = role: builtins.elem role config.modules.system.roles;
  homelabMonitoring = hasRole "homelab-monitoring";
  homelabHostMonitoring = hasRole "homelab-host-monitoring";
  homelabNas = hasRole "homelab-nas";
  promCfg = config.services.prometheus.exporters;
  moduleDir = toString ./.;
  grafanaDashboardsDir = "${moduleDir}/grafana-dashboards";
  prometheusRulesFile = "${moduleDir}/prometheus-rules.yml";
  hasGrafanaDashboards = builtins.pathExists grafanaDashboardsDir;
  hasPrometheusRules = builtins.pathExists prometheusRulesFile;
  ports = {
    grafana = 3000;
    prometheus = 9090;
    alertmanager = 9093;
    promtail = 9080;
    loki = 3100;
    blackbox = 9115;
    nginxExporter = 9113;
    node = 3021;
    unboundExporter = 9167;
    jellyfinExporter = 9715;
    prowlarrExporter = 9710;
    sonarrExporter = 9712;
    radarrExporter = 9711;
    lidarrExporter = 9709;
    bazarrExporter = 9708;
    delugeExporter = 9720;
  };
in
{
  config = {
    users.groups.${config.services.prometheus.exporters.json.group} = { };
    users.users.${config.services.prometheus.exporters.json.user} = {
      isSystemUser = true;
      group = config.services.prometheus.exporters.json.group;
    };
    age.secrets = {
      jellyfin-api = lib.mkIf config.services.prometheus.exporters.json.enable {
        file = ../../secrets/jellyfin-api.age;
        owner = config.services.prometheus.exporters.json.user;
      };
      prowlarr-api = lib.mkIf config.services.prometheus.exporters.exportarr-prowlarr.enable {
        file = ../../secrets/prowlarr-api.age;
        owner = config.services.prometheus.exporters.exportarr-prowlarr.user;
      };
      radarr-api = lib.mkIf config.services.prometheus.exporters.exportarr-radarr.enable {
        file = ../../secrets/radarr-api.age;
        owner = config.services.prometheus.exporters.exportarr-radarr.user;
      };
      sonarr-api = lib.mkIf config.services.prometheus.exporters.exportarr-sonarr.enable {
        file = ../../secrets/sonarr-api.age;
        owner = config.services.prometheus.exporters.exportarr-sonarr.user;
      };
      lidarr-api = lib.mkIf config.services.prometheus.exporters.exportarr-lidarr.enable {
        file = ../../secrets/lidarr-api.age;
        owner = config.services.prometheus.exporters.exportarr-lidarr.user;
      };

      bazarr-api = lib.mkIf config.services.prometheus.exporters.exportarr-bazarr.enable {
        file = ../../secrets/bazarr-api.age;
        owner = config.services.prometheus.exporters.exportarr-bazarr.user;
      };
      deluge-pass = lib.mkIf config.services.prometheus.exporters.deluge.enable {
        file = ../../secrets/deluge-pass.age;
        owner = config.services.prometheus.exporters.deluge.delugeUser;
      };
    };

    services = {
      # individual exporters
      prometheus.exporters = {
        blackbox = {
          enable = homelabMonitoring;
          openFirewall = true;
          port = ports.blackbox;
          enableConfigCheck = false;
          configFile = "/etc/blackbox-exporter/config.yml";
        };
        deluge = {
          enable = config.services.deluge.enable && homelabMonitoring;
          #delugePassword = "deluge";
          delugeUser = "juicy";
          delugePasswordFile = config.age.secrets.deluge-pass.path;
          delugePort = config.services.deluge.config.daemon_port;
          openFirewall = true;
          port = ports.delugeExporter;
        };
        exportarr-bazarr = {
          enable = config.services.bazarr.enable && homelabMonitoring;
          apiKeyFile = config.age.secrets.bazarr-api.path;
          port = ports.bazarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://127.0.0.1:${toString config.services.bazarr.listenPort}";
          openFirewall = true;
          environment = {
            ENABLE_ADDITIONAL_METRICS = "true";
            PROWLARR__BACKFILL = "true";
          };
        };

        exportarr-lidarr = {
          enable = config.services.lidarr.enable && homelabMonitoring;
          apiKeyFile = config.age.secrets.lidarr-api.path;
          port = ports.lidarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://127.0.0.1:${toString config.services.lidarr.settings.server.port}";
          openFirewall = true;
          environment = {
            ENABLE_ADDITIONAL_METRICS = "true";
            PROWLARR__BACKFILL = "true";
          };
        };

        exportarr-prowlarr = {
          enable = config.services.prowlarr.enable && homelabMonitoring;
          apiKeyFile = config.age.secrets.prowlarr-api.path;
          port = ports.prowlarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://127.0.0.1:${toString config.services.prowlarr.settings.server.port}";
          openFirewall = true;
          environment = {
            ENABLE_ADDITIONAL_METRICS = "true";
            PROWLARR__BACKFILL = "true";
          };
        };

        exportarr-radarr = {
          enable = config.services.radarr.enable && homelabMonitoring;
          apiKeyFile = config.age.secrets.radarr-api.path;
          port = ports.radarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://127.0.0.1:${toString config.services.radarr.settings.server.port}";
          openFirewall = true;
          environment = {
            ENABLE_ADDITIONAL_METRICS = "true";
            PROWLARR__BACKFILL = "true";
          };
        };

        exportarr-sonarr = {
          enable = config.services.sonarr.enable && homelabMonitoring;
          apiKeyFile = config.age.secrets.sonarr-api.path;
          port = ports.sonarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://127.0.0.1:${toString config.services.sonarr.settings.server.port}";
          openFirewall = true;
          environment = {
            ENABLE_ADDITIONAL_METRICS = "true";
            PROWLARR__BACKFILL = "true";
          };
        };

        smartctl = {
          enable = homelabNas;
          openFirewall = true;
          maxInterval = "5m";
          devices = [
            "/dev/nvme0"
            "/dev/nvme1"
            "/dev/sdd"
            "/dev/sde"
          ];
        };

        #Jellyfin Exporter
        json = {
          enable = config.services.jellyfin.enable && homelabMonitoring;
          user = "jellyfin-exporter";
          group = "jellyfin-exporter";
          listenAddress = "0.0.0.0";
          port = ports.jellyfinExporter;
          openFirewall = true;
          configFile = "/var/lib/json-exporter/config.yml";
        };

        node = {
          enable = homelabHostMonitoring;
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

        nginx = {
          enable = config.services.nginx.enable && homelabMonitoring;
          port = ports.nginxExporter;
          openFirewall = true;
          listenAddress = "0.0.0.0";
          scrapeUri = "http://127.0.0.1/nginx_status";
        };
      };

      nginx.statusPage = lib.mkIf config.services.prometheus.exporters.nginx.enable true;

      promtail = {
        enable = homelabHostMonitoring;

        configuration = {
          server = {
            http_listen_port = ports.promtail;
            grpc_listen_port = 0;
          };

          positions = {
            filename = "/var/lib/promtail/positions.yaml";
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

      grafana = {
        enable = homelabMonitoring;
        openFirewall = true;

        settings = {
          server = {
            http_addr = "192.168.1.99";
            http_port = ports.grafana;
          };
          security = {
            secret_key = "$__file{/run/grafana/secret_key}";
          };
          metrics.enabled = true;
        };

        provision = {
          enable = config.services.grafana.enable;

          datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              access = "proxy";
              url = "http://zues.home.arpa:${toString ports.prometheus}";
            }
            {
              name = "Loki";
              type = "loki";
              access = "proxy";
              url = "http://zues.home.arpa:${toString ports.loki}";
            }
          ];

          dashboards.settings = {
            apiVersion = 1;
            providers = lib.optional hasGrafanaDashboards {
              name = "homelab";
              folder = "Homelab";
              type = "file";
              disableDeletion = false;
              editable = true;
              options.path = grafanaDashboardsDir;
            };
          };

          alerting = {
            policies.settings = {
              apiVersion = 1;
              policies = [
                {
                  orgId = 1;
                  receiver = "grafana-default-email";
                  group_by = [ "..." ];
                  group_wait = "30s";
                  group_interval = "5m";
                  repeat_interval = "4h";
                }
              ];
            };

            muteTimings.settings = {
              apiVersion = 1;
              muteTimes = [
                {
                  orgId = 1;
                  name = "quiet-hours";
                  time_intervals = [
                    {
                      times = [
                        {
                          start_time = "01:00";
                          end_time = "07:00";
                        }
                      ];
                      weekdays = [ "monday:sunday" ];
                    }
                  ];
                }
              ];
            };
          };
        };
      };

      loki = {
        enable = homelabMonitoring;

        configuration = {
          auth_enabled = false;

          server = {
            http_listen_port = ports.loki;
            http_listen_address = "192.168.1.99";
          };

          common = {
            #instance_addr = "zues.home.arpa";
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
        enable = homelabMonitoring;
        globalConfig.scrape_interval = "60s";
        port = ports.prometheus;
        ruleFiles = lib.optional hasPrometheusRules prometheusRulesFile;
        scrapeConfigs = [
          {
            job_name = "unbound";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString promCfg.unbound.port}" ];
              }
            ];
          }
        ]
        ++ lib.optionals config.services.prometheus.enable [
          {
            job_name = "prometheus";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString ports.prometheus}" ];
              }
            ];
          }
        ]
        ++ lib.optionals config.services.grafana.enable [
          {
            job_name = "grafana";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString ports.grafana}" ];
              }
            ];
          }
        ]
        ++ lib.optionals config.services.loki.enable [
          {
            job_name = "loki";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString ports.loki}" ];
              }
            ];
            metrics_path = "/metrics";
          }
        ]
        ++ lib.optionals config.services.promtail.enable [
          {
            job_name = "promtail";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString ports.promtail}" ];
              }
            ];
            metrics_path = "/metrics";
          }
        ]
        ++ lib.optionals config.services.vaultwarden.enable [
          {
            job_name = "vaultwarden";
            static_configs = [
              {
                targets = [ "zues.home.arpa:8521" ];
              }
            ];
          }
        ]
        ++ lib.optionals promCfg.exportarr-bazarr.enable [
          {
            job_name = "bazarr";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString promCfg.exportarr-bazarr.port}" ];
              }
            ];
          }
        ]
        ++ lib.optionals promCfg.exportarr-lidarr.enable [
          {
            job_name = "lidarr";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString promCfg.exportarr-lidarr.port}" ];
              }
            ];
          }
        ]
        ++ lib.optionals promCfg.exportarr-prowlarr.enable [
          {
            job_name = "prowlarr";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString promCfg.exportarr-prowlarr.port}" ];
              }
            ];
          }
        ]
        ++ lib.optionals promCfg.exportarr-radarr.enable [
          {
            job_name = "radarr";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString promCfg.exportarr-radarr.port}" ];
              }
            ];
          }
        ]
        ++ lib.optionals promCfg.exportarr-sonarr.enable [
          {
            job_name = "sonarr";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString promCfg.exportarr-sonarr.port}" ];
              }
            ];
          }
        ]
        ++ lib.optionals promCfg.smartctl.enable [
          {
            job_name = "smartctl";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString promCfg.smartctl.port}" ];
                labels.instance = "zues";
              }
            ];
          }
        ]
        ++ lib.optionals promCfg.node.enable [
          {
            job_name = "node";
            scrape_interval = "120s";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString ports.node}" ];
                labels.instance = "zues";
              }
            ];
          }
        ]
        ++ lib.optionals promCfg.deluge.enable [
          {
            job_name = "deluge";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString promCfg.deluge.port}" ];
                labels.instance = "zues";
              }
            ];
          }
        ]
        ++ lib.optionals promCfg.nginx.enable [
          {
            job_name = "nginx";
            static_configs = [
              {
                targets = [ "zues.home.arpa:${toString promCfg.nginx.port}" ];
                labels.instance = "zues";
              }
            ];
          }
        ]
        ++ lib.optionals promCfg.blackbox.enable [
          {
            job_name = "blackbox_http";
            metrics_path = "/probe";
            params.module = [ "http_2xx" ];
            static_configs = [
              {
                targets = [
                  "http://jellyfin.home.arpa/web/index.html"
                  "http://vaultwarden.home.arpa"
                  "http://files.home.arpa"
                  "http://grafana.home.arpa"
                  "http://prometheus.home.arpa/-/ready"
                  "http://loki.home.arpa/ready"
                  "http://192.168.1.49:8123"
                  "http://192.168.1.99:8989"
                  "http://192.168.1.99:7878"
                  "http://192.168.1.99:8686"
                  "http://192.168.1.99:6767"
                  "http://192.168.1.99:9696"
                  "https://nixlab.au"
                  "https://pass.nixlab.au"
                  "https://jellyfin.nixlab.au/web/index.html"
                ];
              }
            ];
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                source_labels = [ "__param_target" ];
                target_label = "instance";
              }
              {
                target_label = "__address__";
                replacement = "127.0.0.1:${toString ports.blackbox}";
              }
            ];
          }
          {
            job_name = "blackbox_http_auth";
            metrics_path = "/probe";
            params.module = [ "http_2xx_or_401" ];
            static_configs = [
              {
                targets = [
                  "http://192.168.1.99:9050"
                ];
              }
            ];
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                source_labels = [ "__param_target" ];
                target_label = "instance";
              }
              {
                target_label = "__address__";
                replacement = "127.0.0.1:${toString ports.blackbox}";
              }
            ];
          }
          {
            job_name = "blackbox_tcp";
            metrics_path = "/probe";
            params.module = [ "tcp_connect" ];
            static_configs = [
              {
                targets = [
                  "zues.home.arpa:22"
                  "leo.home.arpa:22"
                  "turn.nixlab.au:3478"
                ];
              }
            ];
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                source_labels = [ "__param_target" ];
                target_label = "instance";
              }
              {
                target_label = "__address__";
                replacement = "127.0.0.1:${toString ports.blackbox}";
              }
            ];
          }
        ]
        ++ lib.optionals promCfg.json.enable [
          {
            job_name = "jellyfin_sessions";
            metrics_path = "/probe";
            params.module = [ "jellyfin" ];
            static_configs = [
              {
                targets = [ "http://jellyfin.home.arpa/Sessions" ];
              }
            ];
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                source_labels = [ "__param_target" ];
                target_label = "instance";
              }
              {
                target_label = "__address__";
                replacement = "127.0.0.1:${toString ports.jellyfinExporter}";
              }
            ];
          }
        ];
      };
    };
    environment.etc."blackbox-exporter/config.yml" = lib.mkIf homelabMonitoring {
      text = ''
        modules:
          http_2xx:
            prober: http
            timeout: 5s
            http:
              preferred_ip_protocol: "ip4"
              valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
          http_2xx_or_401:
            prober: http
            timeout: 5s
            http:
              preferred_ip_protocol: "ip4"
              valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
              valid_status_codes: [200, 401]
          tcp_connect:
            prober: tcp
            timeout: 5s
      '';
    };
    systemd.tmpfiles.rules = lib.mkIf homelabHostMonitoring [
      "d /var/lib/promtail 0750 promtail promtail -"
    ];
    systemd.services.jellyfin-exporter-config =
      lib.mkIf config.services.prometheus.exporters.json.enable
        {
          description = "Render json_exporter config from Jellyfin API secret";
          wantedBy = [ "multi-user.target" ];
          before = [ "prometheus-json-exporter.service" ];
          path = [
            pkgs.coreutils
            pkgs.gnused
          ];

          script = ''
                set -euo pipefail
                TOKEN="$(cat ${config.age.secrets.jellyfin-api.path})"
                umask 077
                cat > "./config.yml" <<'YAML'
            modules:
              jellyfin:
                headers:
                  Authorization: MediaBrowser Token=__TOKEN__
                  Content-Type: application/json
                  accept: application/json
                metrics:
                  - name: jellyfin
                    type: object
                    help: User playback metrics from Jellyfin Sessions
                    path: "{[?(@.NowPlayingItem)]}"
                    labels:
                      user_name: "{ .UserName }"
                      item_type: "{ .NowPlayingItem.Type }"
                      item_name: "{ .NowPlayingItem.Name }"
                      item_path: "{ .NowPlayingItem.Path }"
                      series_name: "{ .NowPlayingItem.SeriesName }"
                      episode_index: "e{ .NowPlayingItem.IndexNumber }"
                      season_index: "s{ .NowPlayingItem.ParentIndexNumber }"
                      client_name: "{ .Client }"
                      device_name: "{ .DeviceName }"
                      session_id: "{ .Id }"
                    values:
                      is_paused: "{ .PlayState.IsPaused }"
            YAML
                # Substitute token safely (escape / and &)
                sed -i "s/__TOKEN__/$(printf '%s' "$TOKEN" | sed 's/[\/&]/\\&/g')/" "./config.yml"
                chmod 0600 "./config.yml"
          '';

          serviceConfig = {
            Type = "oneshot";
            User = config.services.prometheus.exporters.json.user;
            StateDirectory = "json-exporter";
            StateDirectoryMode = "0750";
            UMask = "0066";
            # Optional: make relative paths resolve there
            WorkingDirectory = "%S/json-exporter"; # %S == /var/lib
          };
        };
  };
}
