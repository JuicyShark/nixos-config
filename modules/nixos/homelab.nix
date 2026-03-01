{
  nix-config,
  system,
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption;
  inherit (lib.types) str;
  inherit (nix-config.lib.${system}.roles) mkHasRole;

  srvMountExists = builtins.hasAttr "/srv/chonk" config.fileSystems;

  withSrvMount = lib.mkIf srvMountExists {
    after = [ "srv.mount" ];
    wants = [ "srv.mount" ];
  };

  hasRole = mkHasRole config;
  homelabVaultwarden = hasRole "homelab-vaultwarden";
  homelabJellyfin = hasRole "homelab-jellyfin";
  homelabDeluge = hasRole "homelab-deluge";
  homelabMedia = hasRole "homelab-media";
  homelabNas = hasRole "homelab-nas";

  cfg = config.modules.homelab;

  ports = {
    jellyseerr = 5055;
    jellyfin = 8096;
    delugeWeb = 9050;
    delugeDaemon = 58846;
    vaultwarden = 8521;
    prowlarr = 9696;
    sonarr = 8989;
    radarr = 7878;
    lidarr = 8686;
    bazarr = 6767;
    readarr = 8787;
  };
in
{
  options.modules.homelab = {
    smtpEmail = mkOption {
      type = str;
      default = "noreply@localhost";
      description = "Email address for SMTP notifications";
    };
  };

  config = {
    age.secrets = {
      "vaultwarden.env" = mkIf config.services.vaultwarden.enable {
        file = ../../secrets/vaultwarden.env.age;
        owner = "vaultwarden";
      };

      deluge-auth = lib.mkIf config.services.deluge.enable {
        file = ../../secrets/deluge-auth.age;
        owner = "media";
      };
    };

    users = {
      users.media = mkIf (homelabMedia || homelabDeluge) {
        createHome = false;
        isSystemUser = true;
        group = "media";
      };
      groups.media = {
        name = "media";
        members = [
          "juicy"
        ]
        ++ lib.optionals homelabMedia [
          config.services.jellyfin.user
          config.services.sonarr.user
          config.services.radarr.user
          config.services.lidarr.user
          config.services.bazarr.user
          config.services.readarr.user
        ]
        ++ lib.optional config.services.deluge.enable config.services.deluge.user;
      };
    };

    services = {
      jellyfin = (mkIf homelabJellyfin) {
        enable = true;
        group = "media";
        openFirewall = true;
      };
      jellyseerr = {
        enable = homelabMedia;
        port = ports.jellyseerr;
        openFirewall = true;
      };
      bazarr = {
        enable = homelabMedia;
        user = "media";
        group = "media";
        openFirewall = true;
        listenPort = ports.bazarr;
      };
      prowlarr = {
        enable = homelabMedia;
        openFirewall = true;
        settings.server.port = ports.prowlarr;
      };
      sonarr = {
        enable = homelabMedia;
        user = "media";
        group = "media";
        openFirewall = true;
        settings.server.port = ports.sonarr;
      };
      radarr = {
        enable = homelabMedia;
        user = "media";
        group = "media";
        openFirewall = true;
        settings.server.port = ports.radarr;
      };
      lidarr = {
        enable = homelabMedia;
        user = "media";
        group = "media";
        openFirewall = true;
        settings.server.port = ports.lidarr;
        dataDir = "/var/lib/lidarr/";
      };
      readarr = {
        enable = homelabMedia;
        user = "media";
        group = "media";
        openFirewall = true;
        settings.server.port = ports.readarr;
      };

      deluge = {
        enable = homelabDeluge;
        declarative = true;
        openFirewall = true;
        user = "media";
        group = "media";
        authFile = config.age.secrets.deluge-auth.path;
        config = {
          copy_torrent_file = true;
          move_completed = true;
          torrentfiles_location = "/mnt/chonk/media/torrent/files";
          download_location = "/mnt/chonk/media/torrent/downloading";
          move_completed_path = "/mnt/chonk/media/torrent/data";
          dont_count_slow_torrents = true;
          max_active_seeding = 50;
          max_active_limit = 50;
          max_active_downloading = 4;
          max_connections_global = 150;
          max_upload_speed = 4000;
          max_download_speed = 75000;
          share_ratio_limit = 2;
          allow_remote = false;
          daemon_port = ports.delugeDaemon;
          random_port = false;
          enabled_plugins = [ "Label" ];
        };

        web = {
          enable = homelabDeluge;
          port = ports.delugeWeb;
          openFirewall = true;
        };
      };
      vaultwarden = {
        enable = homelabVaultwarden;
        environmentFile = config.age.secrets."vaultwarden.env".path;
        config = {
          DOMAIN = "https://pass.nixlab.au";
          SIGNUPS_ALLOWED = true;
          ROCKET_ADDRESS = "192.168.1.99";
          ROCKET_PORT = ports.vaultwarden;
          WEB_VAULT_ENABLED = true;
          ENABLE_PROMETHEUS_METRICS = true;
          PUSH_ENABLED = true;
          LOG_LEVEL = "info";
          EXTENDED_LOGGING = false;

          WEBSOCKET_ENABLED = true;
          WEBSOCKET_ADDRESS = "192.168.1.99";
          WEBSOCKET_PORT = 3012;

          SMTP_HOST = "smtp.gmail.com";
          SMTP_PORT = 465;
          SMTP_SECURITY = "force_tls";
          SMTP_FROM = cfg.smtpEmail;
          SMTP_USERNAME = cfg.smtpEmail;
        };
      };
    };
    systemd.services = {
      jellyfin = lib.mkIf config.services.jellyfin.enable withSrvMount;
      jellyseerr = lib.mkIf config.services.jellyseerr.enable withSrvMount;
      deluged = lib.mkIf config.services.deluge.enable withSrvMount;
      deluge-web = lib.mkIf config.services.deluge.web.enable withSrvMount;
      prowlarr = lib.mkIf config.services.prowlarr.enable withSrvMount;
      sonarr = lib.mkIf config.services.sonarr.enable withSrvMount;
      radarr = lib.mkIf config.services.radarr.enable withSrvMount;
      lidarr = lib.mkIf config.services.lidarr.enable withSrvMount;
      bazarr = lib.mkIf config.services.bazarr.enable withSrvMount;
    };
  };
}
