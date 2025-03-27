{
  nix-config,
  config,
  pkgs,
  ...
}: let
  inherit (builtins) attrValues;
in {
  imports = attrValues nix-config.nixosModules;
  home-manager.sharedModules = attrValues nix-config.homeModules;
  environment.systemPackages = attrValues nix-config.packages.${pkgs.system};
  environment.sessionVariables.FLAKE = "/srv/chonk/nix-config";

  networking.firewall.allowedTCPPorts = [8521 8686 9050 3456 2283 8008 80];

  # Custom modules
  modules = {
    desktop.enable = false;
    system = {
      username = "juicy";
      hostName = "dante";
      hashedPassword = "$y$j9T$j5oMkFeAEFqm.TmI9Yql/0$nMZGLBa0Y5E2ORwPbIr1oHVUS2jZJUjFjPPWP.SAmR8";
    };
  };

  # Host Specific Programs
  

  # Host Specific Services
    users = {
      groups.media = {
        name = "media";
        members = [
        config.services.jellyfin.user
        config.services.deluge.user
        config.services.immich.user
        config.services.sonarr.user
        config.services.radarr.user
        config.services.lidarr.user
        config.services.bazarr.user
        config.services.prowlarr.user
        ];
      };
      users.media = {
        isSystemUser = true;
        group = "media";
      };
    };

    services = {
      mullvad-vpn.enable = true;

      vaultwarden = {
        enable = true;
        config = {
          DOMAIN = "https://pass.nixlab.au";
          SIGNUPS_ALLOWED = true;
          ROCKET_ADDRESS = "192.168.1.60";
          ROCKET_PORT = "8521";
          WEB_VAULT_ENABLED = true;
        };
      };

      immich = {
        enable = true;
        host = "192.168.1.60";
        group = "media";
        port = 2283;
        mediaLocation = "/srv/chonk/media/immich";
        machine-learning.enable = true;
        redis.enable = true;
        openFirewall = true;
      };

      jellyfin = {
        enable = true;
        group = "media";
        openFirewall = true;
      };

      deluge = {
        enable = true;
        declarative = false;
        openFirewall = true;
        group = "media";
        #TODO
        #authFile = ;
        config = {
          copy_torrent_file = true;
          move_completed = true;
          group = "media";
          torrentfiles_location = "/srv/chonk/media/torrent/files";
          download_location = "/srv/chonk/media/torrent/downloading";
          move_completed_path = "/srv/chonk/media/torrent/data";
          dont_count_slow_torrents = true;
          max_active_seeding = 98;
          max_active_limit = 100;
          max_active_downloading = 6;
          max_connections_global = 350;
          max_upload_speed = 1250;
          max_download_speed = 3750;
          share_ratio_limit = 2;
          allow_remote = true;
          daemon_port = 58846;
          random_port = false;
          listen_ports = [6881 6889];
          outgoing_interface = "wg0-mullvad";
          enabled_plugins = ["AutoAdd" "Stats" "Label"];
        };

        web = {
          enable = true;
          port = 9050;
          openFirewall = true;
        };
      };
      # Subtitles
      bazarr = {
        enable =  true;
        group = "media";
        openFirewall = true;
      };
      # Indexer
      prowlarr = {
        enable = true;
        openFirewall = true;
      };
      # TV Shows
      sonarr = {
        enable = true;
        group = "media";
        openFirewall = true;
      };
      # Movies
      radarr = {
        enable = true;
        group = "media";
        openFirewall = true;
      };
      # Music
      lidarr = {
        enable = true;
        group = "media";
        openFirewall = true;
      };

      jellyseerr = {
        enable = true;
        port = 5055;
        openFirewall = true;
      };
    };
}
