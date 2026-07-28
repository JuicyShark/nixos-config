# Grafana dashboards, datasources, and alerting policies.
{
  config,
  lib,
  ...
}: let
  homelabMonitoring = config.modules.monitoring.enable;
  inherit (config.modules) ports;
  hostFqdn = "${config.networking.hostName}.home.arpa";
  # Dashboards and rules live alongside this module directory
  dashboardsDir = ../grafana-dashboards;
in {
  config = lib.mkIf homelabMonitoring {
    age.secrets."grafana-secret-key" = {
      file = ../../../secrets/grafana-secret-key.age;
      owner = "grafana";
    };

    services.grafana = {
      enable = true;
      openFirewall = false;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = ports.grafana;
        };
        security.secret_key = "$__file{${config.age.secrets."grafana-secret-key".path}}";
        metrics.enabled = true;
      };
      provision = {
        enable = true;
        datasources.settings = {
          deleteDatasources = [
            {
              name = "Prometheus";
              orgId = 1;
            }
            {
              name = "Loki";
              orgId = 1;
            }
            {
              name = "Alertmanager";
              orgId = 1;
            }
          ];
          datasources = [
            {
              name = "Prometheus";
              uid = "prometheus";
              type = "prometheus";
              isDefault = true;
              access = "proxy";
              url = "http://${hostFqdn}:${toString ports.prometheus}";
            }
            {
              name = "Loki";
              uid = "loki";
              type = "loki";
              access = "proxy";
              url = "http://${hostFqdn}:${toString ports.loki}";
            }
            {
              name = "Alertmanager";
              uid = "alertmanager";
              type = "alertmanager";
              access = "proxy";
              url = "http://${hostFqdn}:${toString ports.alertmanager}";
              jsonData.implementation = "prometheus";
            }
          ];
        };
        dashboards.settings = {
          apiVersion = 1;
          providers = [
            {
              name = "homelab";
              folder = "Homelab";
              type = "file";
              disableDeletion = false;
              editable = false;
              options.path = toString dashboardsDir;
            }
          ];
        };
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        # Default redirect: hostname → grafana
        "${config.networking.hostName}.home.arpa".locations."/" = {
          extraConfig = "return 302 http://grafana.home.arpa;";
        };
        "grafana.home.arpa".locations."/" = {
          proxyPass = "http://127.0.0.1:${toString ports.grafana}";
        };
      };
    };
  };
}
