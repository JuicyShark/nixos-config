# Prometheus exporters — one per monitored service.
# Secrets and the jellyfin-exporter config service live here too.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabMonitoring = config.modules.monitoring.enable;
  homelabHostMonitoring = config.modules.monitoring.host.enable;
  homelabNas = config.modules.monitoring.nas.enable;
  inherit (config.modules) ports;
  exporterPorts = config.modules.ports.exporters;
  username = "juicy";

  mkNixflixService = service: port:
    lib.attrByPath ["nixflix" service] {
      enable = false;
      connectionAddress = "127.0.0.1";
      config.hostConfig.port = port;
    }
    config;

  # Produces an agenix secret entry gated on a service-enable condition.
  mkExporterSecret = secretName: condition: owner:
    lib.mkIf condition {
      file = ../../../secrets/${secretName}.age;
      inherit owner;
    };
in {
  config = {
    users.groups.${config.services.prometheus.exporters.json.group} = {};
    users.users.${config.services.prometheus.exporters.json.user} = {
      isSystemUser = true;
      inherit (config.services.prometheus.exporters.json) group;
    };

    age.secrets = {
      jellyfin-api = mkExporterSecret "jellyfin-api" config.services.prometheus.exporters.json.enable config.services.prometheus.exporters.json.user;
      prowlarr-api = mkExporterSecret "prowlarr-api" config.services.prometheus.exporters.exportarr-prowlarr.enable config.services.prometheus.exporters.exportarr-prowlarr.user;
      radarr-api = mkExporterSecret "radarr-api" config.services.prometheus.exporters.exportarr-radarr.enable config.services.prometheus.exporters.exportarr-radarr.user;
      sonarr-api = mkExporterSecret "sonarr-api" config.services.prometheus.exporters.exportarr-sonarr.enable config.services.prometheus.exporters.exportarr-sonarr.user;
      lidarr-api = mkExporterSecret "lidarr-api" config.services.prometheus.exporters.exportarr-lidarr.enable config.services.prometheus.exporters.exportarr-lidarr.user;
      deluge-pass = mkExporterSecret "deluge-pass" config.services.prometheus.exporters.deluge.enable config.services.prometheus.exporters.deluge.delugeUser;
    };

    services.prometheus.exporters = {
      blackbox = {
        enable = homelabMonitoring;
        openFirewall = false;
        port = exporterPorts.blackbox;
        enableConfigCheck = false;
        configFile = "/etc/blackbox-exporter/config.yml";
      };

      deluge = {
        enable = config.services.deluge.enable && homelabMonitoring;
        delugeUser = username;
        delugePasswordFile = config.age.secrets.deluge-pass.path;
        delugePort = config.services.deluge.config.daemon_port;
        openFirewall = false;
        port = exporterPorts.deluge;
      };

      exportarr-lidarr = {
        enable = (mkNixflixService "lidarr" ports.lidarr).enable && homelabMonitoring;
        apiKeyFile = config.age.secrets.lidarr-api.path;
        port = exporterPorts.lidarr;
        url = let service = mkNixflixService "lidarr" ports.lidarr; in "http://${service.connectionAddress}:${toString service.config.hostConfig.port}";
        openFirewall = false;
        environment = {
          ENABLE_ADDITIONAL_METRICS = "true";
          PROWLARR__BACKFILL = "true";
        };
      };

      exportarr-prowlarr = {
        enable = (mkNixflixService "prowlarr" ports.prowlarr).enable && homelabMonitoring;
        apiKeyFile = config.age.secrets.prowlarr-api.path;
        port = exporterPorts.prowlarr;
        url = let service = mkNixflixService "prowlarr" ports.prowlarr; in "http://${service.connectionAddress}:${toString service.config.hostConfig.port}";
        openFirewall = false;
        environment = {
          ENABLE_ADDITIONAL_METRICS = "true";
          PROWLARR__BACKFILL = "true";
        };
      };

      exportarr-radarr = {
        enable = (mkNixflixService "radarr" ports.radarr).enable && homelabMonitoring;
        apiKeyFile = config.age.secrets.radarr-api.path;
        port = exporterPorts.radarr;
        url = let service = mkNixflixService "radarr" ports.radarr; in "http://${service.connectionAddress}:${toString service.config.hostConfig.port}";
        openFirewall = false;
        environment = {
          ENABLE_ADDITIONAL_METRICS = "true";
          PROWLARR__BACKFILL = "true";
        };
      };

      exportarr-sonarr = {
        enable = (mkNixflixService "sonarr" ports.sonarr).enable && homelabMonitoring;
        apiKeyFile = config.age.secrets.sonarr-api.path;
        port = exporterPorts.sonarr;
        url = let service = mkNixflixService "sonarr" ports.sonarr; in "http://${service.connectionAddress}:${toString service.config.hostConfig.port}";
        openFirewall = false;
        environment = {
          ENABLE_ADDITIONAL_METRICS = "true";
          PROWLARR__BACKFILL = "true";
        };
      };

      smartctl = {
        enable = homelabNas;
        openFirewall = false;
        maxInterval = "5m";
      };

      # Jellyfin sessions exporter via json_exporter
      json = {
        enable = config.services.jellyfin.enable && homelabMonitoring;
        user = "jellyfin-exporter";
        group = "jellyfin-exporter";
        port = exporterPorts.jellyfin;
        openFirewall = false;
        configFile = "/var/lib/json-exporter/config.yml";
      };

      node = {
        enable = homelabHostMonitoring;
        enabledCollectors = ["systemd"];
        openFirewall = false;
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
        port = exporterPorts.node;
      };

      nginx = {
        enable = config.services.nginx.enable && homelabMonitoring;
        port = exporterPorts.nginx;
        openFirewall = false;
        scrapeUri = "http://127.0.0.1/nginx_status";
      };
    };

    services.nginx.statusPage = lib.mkIf config.services.prometheus.exporters.nginx.enable true;

    # Renders the json_exporter config with the Jellyfin API token injected at runtime
    systemd.services.jellyfin-exporter-config =
      lib.mkIf config.services.prometheus.exporters.json.enable
      {
        description = "Render json_exporter config from Jellyfin API secret";
        wantedBy = ["multi-user.target"];
        before = ["prometheus-json-exporter.service"];
        path = [pkgs.coreutils pkgs.gnused];
        script = ''
              set -euo pipefail
              TOKEN="$(cat ${config.age.secrets.jellyfin-api.path})"
              umask 077
              cat > "./config.yml" <<'YAML'
          modules:
            jellyfin:
              headers:
                Authorization: MediaBrowser Token="__TOKEN__", Client="prometheus-json-exporter", Device="zues", DeviceId="zues-jellyfin-exporter", Version="1.0.0"
                X-Emby-Token: __TOKEN__
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
                    active: 1
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
          WorkingDirectory = "%S/json-exporter";
        };
      };
  };
}
