{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modules.homelab;
in
{
  options.modules.homelab = {
    hostMonitoring = mkEnableOption "Host Device Monitoring";
    monitoring = mkEnableOption "Monitoring via Prometheus";
    media = mkEnableOption "Jellyfin and Co";
    nas = mkEnableOption "designate host to share storage";

    nomad = {
      enable = mkEnableOption "Nomad";
      server = mkEnableOption "Nomad Server Node";
      client = mkEnableOption "Nomad Client Node";
    };

  };

  config = {

    users = {
      groups.media = {
        name = "media";
        members = [
          "juicy"
        ]
        ++ lib.optional cfg.media [
          config.services.jellyfin.user
          config.services.sonarr.user
          config.services.radarr.user
          config.services.lidarr.user
          config.services.bazarr.user
        ]
        ++ lib.optional config.services.deluge.enable [ config.services.deluge.user ]
        ++ lib.optional config.services.immich.enable [ config.services.immich.user ];
      };
    };

    services = {
      jellyfin = (mkIf cfg.media) {
        enable = true;
        group = "media";
        openFirewall = true;
      };

      # Subtitles
      bazarr = (mkIf cfg.media) {
        enable = true;
        group = "media";
        openFirewall = true;
      };
      # Indexer
      prowlarr = (mkIf cfg.media) {
        enable = true;
        openFirewall = true;
      };
      # TV Shows
      sonarr = (mkIf cfg.media) {
        enable = true;
        group = "media";
        openFirewall = true;
      };
      # Movies
      radarr = (mkIf cfg.media) {
        enable = true;
        group = "media";
        openFirewall = true;
      };
      # Music
      lidarr = (mkIf cfg.media) {
        enable = true;
        group = "media";
        openFirewall = true;
      };
      deluge = (mkIf config.services.deluge.enable) {
        declarative = true;
        openFirewall = true;
        user = "media";
        group = "media";
        #TODO
        authFile = "/etc/nixos/delugeAuth";
        config = {
          copy_torrent_file = true;
          move_completed = true;
          group = "media";
          torrentfiles_location = "/srv/chonk/media/torrent/files";
          download_location = "/srv/chonk/media/torrent/downloading";
          move_completed_path = "/srv/chonk/media/torrent/data";
          dont_count_slow_torrents = true;
          max_active_seeding = 98;
          max_active_limit = 750;
          max_active_downloading = 6;
          max_connections_global = 350;
          max_upload_speed = 2250;
          max_download_speed = 6750;
          share_ratio_limit = 2;
          allow_remote = false;
          daemon_port = 58846;
          random_port = false;
          outgoing_interface = "enp5s0";
        };

        web = {
          enable = true;
          port = 9050;
          openFirewall = true;
        };
      };

      immich = (mkIf config.services.immich.enable) {
        host = "192.168.1.54";
        group = "media";
        port = 2283;
        mediaLocation = "/srv/chonk/media/immich";
        machine-learning.enable = true;
        redis.enable = true;
        openFirewall = true;
      };

      glances = mkIf (cfg.hostMonitoring) {
        enable = true;
        openFirewall = true;
        port = 55555;
        extraArgs = lib.mkDefault [
          "--webserver"
          "--disable-process"
        ];
      };

      # Network Share
      gvfs.enable = (mkIf cfg.nas) true;
      nfs.server = (mkIf cfg.nas) {
        enable = true;
        exports = "/srv/chonk/ 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)";
      };
      samba = (mkIf cfg.nas) {
        enable = true;
        settings = {
          global = {
            "workgroup" = "nixlab.au";
            "server string" = "smbnix";
            "netbios name" = "smbnix";
            "security" = "user";
            "hosts allow" = "192.168.1. 192.168.1.54 127.0.0.1 localhost";
            "hosts deny" = "0.0.0.0/0";
            "guest account" = "nobody";
            "map to guest" = "bad user";
            "passwd program" = "/run/wrappers/bin/passwd %u";
          };
          "chonk" = {
            "path" = "/srv/chonk/";
            "browseable" = "yes";
            "read only" = "no";
            "guest ok" = "no";
            "force user" = "juicy";
          };
        };
      };
      samba-wsdd = (cfg.nas) {
        enable = true;
        openFirewall = true;
        discovery = true;
        workgroup = "nixlab.au";
      };

      #Nomad
      nomad = (mkIf cfg.nomad.server || cfg.nomad.client) {
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

            /*
              servers = lib.mkDefault [
                "192.168.1.99:4646"
                "192.168.1.54:4646"
                "192.168.1.150:4646"
              ];
            */
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
  };
}
