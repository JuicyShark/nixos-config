# Port Configuration
#
# Centralizes all port definitions for services and exporters.
# This eliminates duplicate port definitions across modules.
#
# Usage:
#   services.jellyfin.port = config.modules.ports.jellyfin;
#   services.prometheus.exportarr.sonarr.port = config.modules.ports.exporters.sonarr;

{ lib, ... }:
with lib;
{
  options.modules.ports = {
    # Web services and dashboards
    grafana = mkOption {
      type = types.port;
      default = 3000;
      description = "Grafana dashboard";
    };

    glance = mkOption {
      type = types.port;
      default = 8080;
      description = "Glance dashboard";
    };

    # Monitoring stack
    prometheus = mkOption {
      type = types.port;
      default = 9090;
      description = "Prometheus server";
    };

    alertmanager = mkOption {
      type = types.port;
      default = 9093;
      description = "Prometheus Alertmanager";
    };

    loki = mkOption {
      type = types.port;
      default = 3100;
      description = "Loki log aggregation";
    };

    promtail = mkOption {
      type = types.port;
      default = 9080;
      description = "Promtail log shipper";
    };

    # Media services
    jellyfin = mkOption {
      type = types.port;
      default = 8096;
      description = "Jellyfin media server";
    };

    jellyseerr = mkOption {
      type = types.port;
      default = 5055;
      description = "Jellyseerr request management";
    };

    # Media management (*arr stack)
    prowlarr = mkOption {
      type = types.port;
      default = 9696;
      description = "Prowlarr indexer manager";
    };

    sonarr = mkOption {
      type = types.port;
      default = 8989;
      description = "Sonarr TV show management";
    };

    radarr = mkOption {
      type = types.port;
      default = 7878;
      description = "Radarr movie management";
    };

    lidarr = mkOption {
      type = types.port;
      default = 8686;
      description = "Lidarr music management";
    };

    bazarr = mkOption {
      type = types.port;
      default = 6767;
      description = "Bazarr subtitle management";
    };

    readarr = mkOption {
      type = types.port;
      default = 8787;
      description = "Readarr book management";
    };

    # Download clients
    delugeWeb = mkOption {
      type = types.port;
      default = 9050;
      description = "Deluge web interface";
    };

    delugeDaemon = mkOption {
      type = types.port;
      default = 58846;
      description = "Deluge daemon";
    };

    # Other services
    vaultwarden = mkOption {
      type = types.port;
      default = 8521;
      description = "Vaultwarden password manager";
    };

    filebrowser = mkOption {
      type = types.port;
      default = 8084;
      description = "File browser";
    };

    # Prometheus exporters
    exporters = {
      node = mkOption {
        type = types.port;
        default = 9100;
        description = "Node exporter";
      };

      nginx = mkOption {
        type = types.port;
        default = 9113;
        description = "Nginx exporter";
      };

      blackbox = mkOption {
        type = types.port;
        default = 9115;
        description = "Blackbox exporter";
      };

      unbound = mkOption {
        type = types.port;
        default = 9167;
        description = "Unbound DNS exporter";
      };

      smartctl = mkOption {
        type = types.port;
        default = 9633;
        description = "Smartctl disk health exporter";
      };

      zfs = mkOption {
        type = types.port;
        default = 9134;
        description = "ZFS exporter";
      };

      # Media service exporters (exportarr)
      jellyfin = mkOption {
        type = types.port;
        default = 9707;
        description = "Jellyfin exporter";
      };

      prowlarr = mkOption {
        type = types.port;
        default = 9710;
        description = "Prowlarr exporter";
      };

      sonarr = mkOption {
        type = types.port;
        default = 9712;
        description = "Sonarr exporter";
      };

      radarr = mkOption {
        type = types.port;
        default = 9711;
        description = "Radarr exporter";
      };

      lidarr = mkOption {
        type = types.port;
        default = 9709;
        description = "Lidarr exporter";
      };

      bazarr = mkOption {
        type = types.port;
        default = 9708;
        description = "Bazarr exporter";
      };

      deluge = mkOption {
        type = types.port;
        default = 9720;
        description = "Deluge exporter";
      };
    };

    # Sunshine game streaming
    sunshine = {
      https = mkOption {
        type = types.port;
        default = 47984;
        description = "Sunshine HTTPS port";
      };

      http = mkOption {
        type = types.port;
        default = 47989;
        description = "Sunshine HTTP port";
      };

      web = mkOption {
        type = types.port;
        default = 47990;
        description = "Sunshine web UI port";
      };
    };
  };
}
