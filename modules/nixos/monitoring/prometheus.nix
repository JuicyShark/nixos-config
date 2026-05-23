{
  self,
  config,
  pkgs,
  lib,
  ...
}: let
  endpoints = self.lib.${pkgs.stdenv.hostPlatform.system}.services.mkHomelabEndpoints {inherit config;};
  networkCfg = config.modules.network;
  homelabMonitoring = config.modules.monitoring.enable;
  promCfg = config.services.prometheus.exporters;
  inherit (config.modules) ports;
  exporterPorts = config.modules.ports.exporters;
  hostname = config.networking.hostName;
  localTarget = port: "127.0.0.1:${toString port}";
  rulesFile = ./prometheus-rules.yml;

  mkLocalScrape = jobName: port: {
    job_name = jobName;
    static_configs = [{targets = [(localTarget port)];}];
    metrics_path = "/metrics";
  };

  mkOptionalLocalScrape = condition: jobName: port:
    lib.optionals condition [(mkLocalScrape jobName port)];

  mkAlloyScrape = lib.optionals config.services.alloy.enable [
    {
      job_name = "alloy";
      static_configs = [
        {
          targets = [(localTarget ports.alloy)];
          labels = {
            instance = hostname;
            host = hostname;
          };
        }
        {
          targets = ["${networkCfg.hosts.fallarbor}:${toString ports.alloy}"];
          labels = {
            instance = "fallarbor";
            host = "fallarbor";
          };
        }
      ];
      metrics_path = "/metrics";
    }
  ];

  mkExporterScrape = jobName: exporter:
    mkOptionalLocalScrape exporter.enable jobName exporter.port;

  mkInstanceScrape = jobName: instance: port:
    lib.optionals port.enable [
      {
        job_name = jobName;
        static_configs = [
          {
            targets = [(localTarget port.port)];
            labels.instance = instance;
          }
        ];
      }
    ];

  blackboxRelabel = exporterPort: [
    {
      source_labels = ["__address__"];
      target_label = "__param_target";
    }
    {
      source_labels = ["__param_target"];
      target_label = "instance";
    }
    {
      target_label = "__address__";
      replacement = "127.0.0.1:${toString exporterPort}";
    }
  ];

  mkBlackboxScrape = {
    jobName,
    module,
    targets,
  }: {
    job_name = jobName;
    metrics_path = "/probe";
    params.module = [module];
    static_configs = [{inherit targets;}];
    relabel_configs = blackboxRelabel exporterPorts.blackbox;
  };
in {
  config = {
    services = {
      prometheus = {
        enable = homelabMonitoring;
        retentionTime = "30d";
        globalConfig.scrape_interval = "60s";
        port = ports.prometheus;
        ruleFiles = [rulesFile];
        alertmanagers = lib.optional homelabMonitoring {
          static_configs = [{targets = ["127.0.0.1:${toString ports.alertmanager}"];}];
        };
        scrapeConfigs =
          [
            (mkLocalScrape "unbound" promCfg.unbound.port)
          ]
          ++ mkOptionalLocalScrape config.services.prometheus.enable "prometheus" ports.prometheus
          ++ mkOptionalLocalScrape config.services.grafana.enable "grafana" ports.grafana
          ++ mkOptionalLocalScrape config.services.loki.enable "loki" ports.loki
          ++ mkAlloyScrape
          ++ mkOptionalLocalScrape config.services.vaultwarden.enable "vaultwarden" ports.vaultwarden
          ++ mkExporterScrape "lidarr" promCfg.exportarr-lidarr
          ++ mkExporterScrape "prowlarr" promCfg.exportarr-prowlarr
          ++ mkExporterScrape "radarr" promCfg.exportarr-radarr
          ++ mkExporterScrape "sonarr" promCfg.exportarr-sonarr
          ++ lib.optionals promCfg.smartctl.enable [
            {
              job_name = "smartctl";
              static_configs = [
                {
                  targets = [(localTarget promCfg.smartctl.port)];
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
                  targets = [(localTarget exporterPorts.node)];
                  labels.instance = "zues";
                }
                {
                  targets = ["${networkCfg.hosts.fallarbor}:${toString exporterPorts.node}"];
                  labels.instance = "fallarbor";
                }
              ];
            }
          ]
          ++ mkInstanceScrape "deluge" "zues" promCfg.deluge
          ++ mkInstanceScrape "nginx" "zues" promCfg.nginx
          ++ lib.optionals promCfg.blackbox.enable [
            (mkBlackboxScrape {
              jobName = "blackbox_http";
              module = "http_2xx";
              targets = endpoints.blackboxHttpTargets;
            })
            (mkBlackboxScrape {
              jobName = "blackbox_http_auth";
              module = "http_2xx_or_401";
              targets = endpoints.blackboxHttpAuthTargets;
            })
            (mkBlackboxScrape {
              jobName = "blackbox_tcp";
              module = "tcp_connect";
              targets = endpoints.blackboxTcpTargets;
            })
          ]
          ++ lib.optionals promCfg.json.enable [
            {
              job_name = "jellyfin_sessions";
              metrics_path = "/probe";
              params.module = ["jellyfin"];
              static_configs = [{targets = ["http://jellyfin.home.arpa/Sessions"];}];
              relabel_configs = [
                {
                  source_labels = ["__address__"];
                  target_label = "__param_target";
                }
                {
                  source_labels = ["__param_target"];
                  target_label = "instance";
                }
                {
                  target_label = "__address__";
                  replacement = "127.0.0.1:${toString exporterPorts.jellyfin}";
                }
              ];
            }
          ];

        alertmanager = lib.mkIf homelabMonitoring {
          enable = true;
          port = ports.alertmanager;
          configuration = {
            route = {
              receiver = "null";
              group_wait = "30s";
              group_interval = "5m";
              repeat_interval = "4h";
            };
            receivers = [{name = "null";}];
          };
        };
      };

      nginx.virtualHosts = lib.mkIf homelabMonitoring {
        "prometheus.home.arpa" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString ports.prometheus}";
          };
          extraConfig = ''
            allow ${networkCfg.subnets.lan};
            allow ${networkCfg.subnets.tailscale};
            deny all;
          '';
        };
        "alertmanager.home.arpa" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString ports.alertmanager}";
          };
          extraConfig = ''
            allow ${networkCfg.subnets.lan};
            allow ${networkCfg.subnets.tailscale};
            deny all;
          '';
        };
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
  };
}
