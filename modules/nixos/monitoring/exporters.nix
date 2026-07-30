# Prometheus exporters — one per monitored service.
# Host-health textfiles, secrets, and Jellyfin exporter config rendering live here too.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabMonitoring = config.modules.monitoring.enable;
  homelabHostMonitoring = config.modules.monitoring.host.enable;
  homelabNas = config.modules.monitoring.nas.enable;
  homelabJellyfin = config.modules.homelab.jellyfin.enable or false;
  btrfsMounts = config.services.btrfs.autoScrub.fileSystems or [];
  writablePaths = config.modules.monitoring.writablePaths;
  vpnGuard = config.modules.monitoring.vpnGuard;
  inherit (config.modules) ports;
  exporterPorts = config.modules.ports.exporters;
  textfileDirectory = "/var/lib/node-exporter-textfiles";

  homelabHealthMetrics = pkgs.writeShellApplication {
    name = "homelab-health-metrics";
    runtimeInputs = with pkgs; [
      btrfs-progs
      coreutils
      gawk
      gnugrep
      iproute2
      systemd
      util-linux
    ];
    text = builtins.readFile ./homelab-health-metrics.sh;
  };

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

  renderJellyfinExporterConfig = pkgs.writeShellScript "render-jellyfin-exporter-config" ''
    set -euo pipefail

    TOKEN="$(${pkgs.coreutils}/bin/cat ${config.age.secrets.jellyfin-api.path})"
    umask 077
    ${pkgs.coreutils}/bin/cat > /var/lib/json-exporter/config.yml <<'YAML'
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
    ${pkgs.gnused}/bin/sed -i \
      "s/__TOKEN__/$(printf '%s' "$TOKEN" | ${pkgs.gnused}/bin/sed 's/[\/&]/\\&/g')/" \
      /var/lib/json-exporter/config.yml
    ${pkgs.coreutils}/bin/chmod 0600 /var/lib/json-exporter/config.yml
  '';
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
    };

    services.prometheus.exporters = {
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
        enable = homelabJellyfin && homelabMonitoring;
        user = "jellyfin-exporter";
        group = "jellyfin-exporter";
        port = exporterPorts.jellyfin;
        openFirewall = false;
        configFile = "/var/lib/json-exporter/config.yml";
        # json_exporter logs its fully rendered config at info level, including
        # request headers. Keep the runtime-injected Jellyfin key out of the
        # journal.
        extraFlags = ["--log.level=warn"];
      };

      node = {
        enable = homelabHostMonitoring;
        enabledCollectors = [
          "systemd"
          "textfile"
        ];
        openFirewall = false;
        extraFlags = [
          "--collector.textfile.directory=${textfileDirectory}"
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

    systemd = {
      tmpfiles.rules = lib.mkIf homelabHostMonitoring [
        "d ${textfileDirectory} 0755 root root -"
      ];

      services.homelab-health-metrics = lib.mkIf (homelabHostMonitoring && (btrfsMounts != [] || writablePaths != [] || vpnGuard.service != "")) {
        description = "Export host health metrics for node_exporter";
        environment = {
          HOMELAB_BTRFS_MOUNTS = lib.concatStringsSep ":" btrfsMounts;
          HOMELAB_METRICS_OUTPUT_DIR = textfileDirectory;
          HOMELAB_WRITABLE_PATHS = lib.concatStringsSep ":" writablePaths;
          HOMELAB_VPN_NAMESPACE = vpnGuard.namespace;
          HOMELAB_VPN_SERVICE = vpnGuard.service;
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe homelabHealthMetrics;
          UMask = "0022";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          ReadWritePaths = [textfileDirectory];
        };
      };

      timers.homelab-health-metrics = lib.mkIf (homelabHostMonitoring && (btrfsMounts != [] || writablePaths != [] || vpnGuard.service != "")) {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "15m";
          RandomizedDelaySec = "2m";
          Persistent = true;
        };
      };

      # Render immediately before every exporter start. A stale or partially
      # written config can no longer survive a successful renderer run.
      services.prometheus-json-exporter = lib.mkIf config.services.prometheus.exporters.json.enable {
        restartTriggers = [config.age.secrets.jellyfin-api.file];
        serviceConfig = {
          StateDirectory = "json-exporter";
          StateDirectoryMode = "0750";
          ExecStartPre = [renderJellyfinExporterConfig];
        };
      };
    };
  };
}
