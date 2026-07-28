{
  self,
  config,
  lib,
  ...
}: let
  endpoints = self.lib.services.mkHomelabEndpoints {inherit config;};
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
          targets = ["100.112.235.76:${toString ports.alloy}"];
          labels = {
            instance = "fallarbor";
            host = "fallarbor";
          };
        }
        {
          targets = ["192.168.1.54:${toString ports.alloy}"];
          labels = {
            instance = "leo";
            host = "leo";
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
in {
  config = {
    services = {
      prometheus = {
        enable = homelabMonitoring;
        retentionTime = "30d";
        globalConfig.scrape_interval = "60s";
        port = ports.prometheus;
        ruleFiles = [rulesFile];
        scrapeConfigs =
          [
            (mkLocalScrape "unbound" promCfg.unbound.port)
          ]
          ++ mkOptionalLocalScrape config.services.prometheus.enable "prometheus" ports.prometheus
          ++ mkOptionalLocalScrape config.services.prometheus.alertmanager.enable "alertmanager" ports.alertmanager
          ++ mkOptionalLocalScrape config.services.grafana.enable "grafana" ports.grafana
          ++ mkOptionalLocalScrape config.services.loki.enable "loki" ports.loki
          ++ mkAlloyScrape
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
                  targets = ["100.112.235.76:${toString exporterPorts.node}"];
                  labels.instance = "fallarbor";
                }
                {
                  targets = ["192.168.1.54:${toString exporterPorts.node}"];
                  labels.instance = "leo";
                }
              ];
            }
          ]
          ++ mkInstanceScrape "nginx" "zues" promCfg.nginx
          ++ lib.optionals promCfg.json.enable [
            {
              job_name = "jellyfin_sessions";
              metrics_path = "/probe";
              params.module = ["jellyfin"];
              static_configs = [{targets = ["${endpoints.services.jellyfin.url}/Sessions"];}];
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
      };

      nginx.virtualHosts = lib.mkIf config.services.prometheus.enable {
        "prometheus.home.arpa" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString ports.prometheus}";
          };
          extraConfig = ''
            allow 192.168.1.0/24;
            allow 100.64.0.0/10;
            deny all;
          '';
        };
      };
    };
  };
}
