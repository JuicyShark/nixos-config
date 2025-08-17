{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;

  srvMountExists = builtins.hasAttr "/srv/chonk" config.fileSystems;

  withSrvMount = lib.mkIf srvMountExists {
    after = [ "srv.mount" ];
    wants = [ "srv.mount" ];
  };

  iface = config.networking.defaultGateway.interface;
  ip = (builtins.elemAt config.networking.interfaces.${iface}.ipv4.addresses 0).address;

  cfg = config.modules.homelab;

  hosts = {
    leo = "192.168.1.54";
    imp = "192.168.1.53";
    zues = "192.168.1.99";
    emerald = "192.168.1.150";
    Kunzite = "192.168.1.155";
    router = "192.168.1.1";
    home-assist = "192.168.1.59";
  };

  ports = {
    jellyseerr = 5055;
    jellyfin = 8096;
    immich = 2283;
    delugeWeb = 9050;
    delugeDaemon = 58846;
    delugeExporter = 9720;
    vaultwarden = 8521;
    matrix = 8008;
    prowlarr = 9696;
    sonarr = 8989;
    radarr = 7878;
    lidarr = 8686;
    bazarr = 6767;
    unboundExporter = 9167;
    prowlarrExporter = 9710;
    sonarrExporter = 9712;
    radarrExporter = 9711;
    lidarrExporter = 9709;
    bazarrExporter = 9708;
    nodeExporter = 3021;

  };
in
{
  options.modules.homelab = {
    hostMonitoring = mkEnableOption "Host Device Monitoring";
    monitoring = mkEnableOption "Monitoring via Prometheus";
    vaultwarden = mkEnableOption "Vaultwarden support";
    matrix-server = mkEnableOption "Matrix Server";
    adguard-home = mkEnableOption "Adguard Support";
    jellyfin = mkEnableOption "jellyfin host";
    deluge = mkEnableOption "Linux Iso grabber host";
    immich = mkEnableOption "photo cloud";
    llm = mkEnableOption "Ai time";
    media = mkEnableOption "Jellyfin and Co";
    nas = mkEnableOption "designate host to share storage";

    nomad = {
      enable = mkEnableOption "Nomad";
      server = mkEnableOption "Nomad Server Node";
      client = mkEnableOption "Nomad Client Node";
    };
  };

  config = {

    age.secrets = {
      prowlarr-api = mkIf config.services.prowlarr.enable {
        file = ../secrets/prowlarr-api.age;
      };
      radarr-api = mkIf config.services.radarr.enable {
        file = ../secrets/radarr-api.age;
      };
      sonarr-api = mkIf config.services.sonarr.enable {
        file = ../secrets/sonarr-api.age;
      };
      lidarr-api = mkIf config.services.lidarr.enable {
        file = ../secrets/lidarr-api.age;
      };

      bazarr-api = mkIf config.services.bazarr.enable {
        file = ../secrets/bazarr-api.age;
      };

      vaultwarden-push-id = mkIf config.services.vaultwarden.enable {
        file = ../secrets/vaultwarden-push-id.age;
      };

      vaultwarden-push-key = mkIf config.services.vaultwarden.enable {
        file = ../secrets/vaultwarden-push-key.age;
      };

      deluge-auth = lib.mkIf config.services.deluge.enable {
        file = ../secrets/deluge-auth.age;
        owner = "deluge";
        group = "media";
      };
      matrix-shared-key = lib.mkIf config.services.matrix-synapse.enable {
        file = ../secrets/matrix-shared-key.age;
        # owner = "matrix";
        #group = "matrix";
      };
      /*
        coturn-key = lib.mkIf config.services.coturn.enable {
          file = ../secrets/coturn-key.age;
          #owner = "matrix";
          #group = "matrix";
        };
      */
    };

    users = {
      groups.media = {
        name = "media";
        members = [
          "juicy"
        ]
        ++ lib.optionals cfg.media [
          config.services.jellyfin.user
          config.services.sonarr.user
          config.services.radarr.user
          config.services.lidarr.user
          config.services.bazarr.user
        ]
        ++ lib.optional config.services.deluge.enable config.services.deluge.user
        ++ lib.optional config.services.immich.enable config.services.immich.user;
      };
    };

    services = {
      jellyfin = (mkIf config.services.jellyfin.enable) {
        group = "media";
        openFirewall = true;
      };
      jellyseerr = {
        enable = mkIf cfg.media true;
        port = ports.jellyseerr;
        openFirewall = true;
      };

      # Subtitles
      bazarr = {
        enable = mkIf cfg.media true;
        group = "media";
        openFirewall = true;
        listenPort = ports.bazarr;
      };
      # Indexer
      prowlarr = {
        enable = mkIf cfg.media true;
        openFirewall = true;
        settings.server.port = ports.prowlarr;
      };
      # TV Shows
      sonarr = {
        enable = mkIf cfg.media true;
        group = "media";
        openFirewall = true;
        settings.server.port = ports.sonarr;
      };
      # Movies
      radarr = {
        enable = mkIf cfg.media true;
        group = "media";
        openFirewall = true;
        settings.server = {
          port = ports.radarr;
        };
      };
      # Music
      lidarr = {
        enable = mkIf cfg.media true;
        group = "media";
        openFirewall = true;
        settings.server.port = ports.lidarr;
        dataDir = "/var/lib/lidarr/";
      };

      deluge = {
        enable = mkIf cfg.deluge true;
        declarative = true;
        openFirewall = true;
        group = "media";
        authFile = config.age.secrets.deluge-auth.path;
        config = {
          copy_torrent_file = true;
          move_completed = true;
          group = "media";
          torrentfiles_location = "/srv/chonk/media/torrent/files";
          download_location = "/srv/chonk/media/torrent/downloading";
          move_completed_path = "/srv/chonk/media/torrent/data";
          dont_count_slow_torrents = true;
          max_active_seeding = 745;
          max_active_limit = 750;
          max_active_downloading = 10;
          max_connections_global = 350;
          max_upload_speed = 3750;
          max_download_speed = 12750;
          share_ratio_limit = 2;
          allow_remote = false;
          daemon_port = ports.delugeDaemon;
          random_port = false;
          outgoing_interface = iface;
          enabled_plugins = [
            "label"
          ];
        };

        web = {
          enable = mkIf cfg.deluge true;
          port = ports.delugeWeb;
          openFirewall = true;
        };
      };

      #Vault Warden
      vaultwarden = {
        enable = mkIf cfg.vaultwarden true;
        config = {
          DOMAIN = "https://pass.nixlab.au";
          SIGNUPS_ALLOWED = true;
          ROCKET_ADDRESS = "192.168.1.99";
          ROCKET_PORT = ports.vaultwarden;
          WEB_VAULT_ENABLED = true;
          ENABLE_PROMETHEUS_METRICS = true;
          PUSH_ENABLED = true;

          PUSH_INSTALLATION_ID = config.age.secrets.vaultwarden-push-id.path;
          PUSH_INSTALLATION_KEY = config.age.secrets.vaultwarden-push-key.path;
        };
      };

      adguardhome = {
        enable = mkIf cfg.adguard-home true;
        mutableSettings = true;
        openFirewall = true;
      };

      immich = {
        enable = mkIf cfg.immich true;
        host = "192.168.1.54";
        group = "media";
        port = ports.immich;
        mediaLocation = "/srv/chonk/media/immich";
        machine-learning.enable = true;
        redis.enable = true;
        openFirewall = true;
      };

      # Network Share
      gvfs.enable = (mkIf cfg.nas) true;
      rpcbind.enable = (mkIf cfg.nas) true;
      nfs.server = (mkIf cfg.nas) {
        enable = true;
        hostName = "nas.lan";
        lockdPort = 4001;
        mountdPort = 4002;
        statdPort = 4000;
        exports = "/srv/chonk/ 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash,insecure)";
      };

      prometheus.exporters = {
        deluge = {
          enable = mkIf config.services.deluge.enable true;
          delugePasswordFile = config.age.secrets.deluge-auth.path;
          delugePort = config.services.deluge.config.daemon_port;
          openFirewall = true;
          port = ports.delugeExporter;
        };
        exportarr-bazarr = {
          enable = mkIf config.services.bazarr.enable true;
          apiKeyFile = config.age.secrets.bazarr-api.path;
          port = ports.bazarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://leo.lan:${toString ports.bazarr}";
          openFirewall = true;
        };

        exportarr-lidarr = {
          enable = mkIf config.services.lidarr.enable true;
          apiKeyFile = config.age.secrets.lidarr-api.path;
          port = ports.lidarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://leo.lan:${toString ports.lidarr}";
          openFirewall = true;
        };

        exportarr-prowlarr = {
          enable = mkIf config.services.prowlarr.enable true;
          apiKeyFile = config.age.secrets.prowlarr-api.path;
          port = ports.prowlarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://leo.lan:${toString ports.prowlarr}";
          openFirewall = true;
        };

        exportarr-radarr = {
          enable = mkIf config.services.radarr.enable true;
          apiKeyFile = config.age.secrets.radarr-api.path;
          port = ports.radarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://leo.lan:${toString ports.radarr}";
          openFirewall = true;
        };

        exportarr-sonarr = {
          enable = mkIf config.services.sonarr.enable true;
          apiKeyFile = config.age.secrets.sonarr-api.path;
          port = ports.sonarrExporter;
          listenAddress = "0.0.0.0";
          url = "http://leo.lan:${toString ports.sonarr}";
          openFirewall = true;
        };

        smartctl = {
          enable = mkIf cfg.hostMonitoring true;
          openFirewall = true;
        };

        node = {
          enable = mkIf cfg.hostMonitoring true;
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

          port = ports.nodeExporter;
        };
      };
      matrix-synapse = {
        enable = mkIf cfg.matrix-server true;
        enableRegistrationScript = true;

        settings = {
          server_name = "nixlab.au";
          public_baseurl = "https://matrix.nixlab.au";

          enable_registration = true;
          enable_registration_without_verification = true;
          registration_shared_secrets = config.age.secrets.matrix-shared-key.path;
          turn_shared_sercet = config.age.secrets.coturn-key.path;
          turn_uris = [
            "turn:turn.nixlab.au:3478?transport=udp"
          ];
          # Optional but recommended tuning if you see rate-limit noise:
          rc_message = {
            per_second = 0.5;
            burst_count = 30;
          };
          rc_delayed_event_mgmt = {
            per_second = 1;
            burst_count = 20;
          };

          experimental_features = {
            msc3266_enabled = true; # room summary
            msc4222_enabled = true; # syncv2 state_after
            msc4140_enabled = true; # delayed events for call signalling
          };
          listeners = [
            {
              port = ports.matrix;
              bind_addresses = [
                "192.168.1.99"
                "::1"
                "127.0.0.1"
              ];
              type = "http";
              tls = false;
              x_forwarded = true;
              resources = [
                {
                  names = [
                    "client"
                    "federation"
                  ];
                  compress = false;
                }
              ];
            }
          ];

          database = {
            name = "sqlite3";
            args = {
              database = "/var/lib/matrix-synapse/homeserver.db";
            };
          };
        };
      };

      #Nomad
      /*
        nomad = mkIf (cfg.nomad.server || cfg.nomad.client) {
          enable = true;
          dropPrivileges = false;
          settings = {
            datacenter = "home";
            region = "local";
            # node_name = config.networking.hostName;

            server = (mkIf cfg.nomad.server) {
              enabled = lib.mkDefault false; # override on server node
              bootstrap_expect = 1;
              server_join = {
                retry_join = [
                  "192.168.1.99"
                  "192.168.1.54"
                ];
                retry_max = 3;
                retry_interval = "15s";

              };

              client = (mkIf cfg.nomad.client) {
                enabled = true;
                server_join = {
                  retry_join = [
                    "192.168.1.99"
                    "192.168.1.54"
                  ];
                  retry_max = 3;
                  retry_interval = "15s";
                };

                  servers = lib.mkDefault [
                    "192.168.1.99:4646"
                    "192.168.1.54:4646"
                    "192.168.1.150:4646"
                  ];

                options = {
                  "driver.raw_exec.enable" = "1"; # for running scripts
                  "driver.exec.enable" = "1"; # enables local command execution
                };
              };
              consul = {
                enable = true;
                address = "192.168.1.99:8500";
                client_auto_join = true;
                server_auto_join = true;
              };
              # plugin = [ { docker.config.volume.enabled = true; } ];
            };
          };

        };
      */
    };
    networking.firewall.allowedUDPPorts = [ 3478 ];
    systemd.services = {
      jellyfin = lib.mkIf config.services.jellyfin.enable (withSrvMount);
      jellyseerr = lib.mkIf cfg.media (withSrvMount);
      deluged = lib.mkIf config.services.deluge.enable (withSrvMount);
      deluge-web = lib.mkIf config.services.deluge.web.enable (withSrvMount);
      immich = lib.mkIf config.services.immich.enable (withSrvMount);

      prowlarr = lib.mkIf config.services.prowlarr.enable (withSrvMount);
      sonarr = lib.mkIf config.services.sonarr.enable (withSrvMount);
      radarr = lib.mkIf config.services.radarr.enable (withSrvMount);
      lidarr = lib.mkIf config.services.lidarr.enable (withSrvMount);
      bazarr = lib.mkIf config.services.bazarr.enable (withSrvMount);
    };
  };
}
