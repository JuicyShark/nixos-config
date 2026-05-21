# Media acquisition stack: jellyfin, jellyseerr, and the *arr suite.
# Also manages the shared media user/group that all services run under.
{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;

  homelabJellyfin = config.modules.homelab.jellyfin.enable;
  homelabMedia = config.modules.homelab.media.enable;
  homelabDeluge = config.modules.homelab.deluge.enable;

  inherit (config.modules) ports;
  networkCfg = config.modules.network;
  inherit (config.modules.system) username;

  srvMountExists = builtins.hasAttr "/srv/chonk" config.fileSystems;
  withSrvMount = {
    after = ["srv.mount"];
    wants = ["srv.mount"];
  };
in {
  config = {
    users = {
      users.media = mkIf (homelabMedia || homelabDeluge) {
        createHome = false;
        isSystemUser = true;
        uid = 2000;
        group = "media";
      };
      groups.media = {
        name = "media";
        gid = 2000;
        members =
          [
            username
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
      jellyfin = mkIf homelabJellyfin {
        enable = true;
        group = "media";
        openFirewall = false;
      };
      seerr = {
        enable = homelabMedia;
        port = ports.jellyseerr;
        openFirewall = false;
      };
      bazarr = {
        enable = homelabMedia;
        user = "media";
        group = "media";
        openFirewall = false;
        listenPort = ports.bazarr;
      };
      prowlarr = {
        enable = homelabMedia;
        openFirewall = false;
        settings = {
          server.port = ports.prowlarr;
          server.bindaddress = "127.0.0.1";
          log.analyticsEnabled = false;
        };
      };
      sonarr = {
        enable = homelabMedia;
        user = "media";
        group = "media";
        openFirewall = false;
        settings = {
          server.port = ports.sonarr;
          server.bindaddress = "127.0.0.1";
          log.analyticsEnabled = false;
        };
      };
      radarr = {
        enable = homelabMedia;
        user = "media";
        group = "media";
        openFirewall = false;
        settings = {
          server.port = ports.radarr;
          server.bindaddress = "127.0.0.1";
          log.analyticsEnabled = false;
        };
      };
      lidarr = {
        enable = homelabMedia;
        user = "media";
        group = "media";
        openFirewall = false;
        dataDir = "/var/lib/lidarr/";
        settings = {
          server.port = ports.lidarr;
          server.bindaddress = "127.0.0.1";
          log.analyticsEnabled = false;
        };
      };
      readarr = {
        enable = homelabMedia;
        user = "media";
        group = "media";
        openFirewall = false;
        settings = {
          server.port = ports.readarr;
          server.bindaddress = "127.0.0.1";
          log.analyticsEnabled = false;
        };
      };

      nginx = {
        enable = mkIf (homelabMedia || homelabJellyfin || homelabDeluge) true;
        virtualHosts =
          lib.optionalAttrs homelabJellyfin {
            # Jellyfin needs WebSocket upgrade for live TV / casting
            "jellyfin.home.arpa".locations."/" = {
              proxyPass = "http://${networkCfg.hosts.imac-machop}:${toString ports.jellyfin}";
              extraConfig = ''
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
              '';
            };
          }
          // lib.optionalAttrs homelabMedia {
            "sonarr.home.arpa".locations."/" = {
              proxyPass = "http://127.0.0.1:${toString ports.sonarr}";
            };
            "radarr.home.arpa".locations."/" = {
              proxyPass = "http://127.0.0.1:${toString ports.radarr}";
            };
            "lidarr.home.arpa".locations."/" = {
              proxyPass = "http://127.0.0.1:${toString ports.lidarr}";
            };
            "readarr.home.arpa".locations."/" = {
              proxyPass = "http://127.0.0.1:${toString ports.readarr}";
            };
            "prowlarr.home.arpa".locations."/" = {
              proxyPass = "http://127.0.0.1:${toString ports.prowlarr}";
            };
            "bazarr.home.arpa".locations."/" = {
              proxyPass = "http://127.0.0.1:${toString ports.bazarr}";
            };
            "seerr.home.arpa".locations."/" = {
              proxyPass = "http://127.0.0.1:${toString ports.jellyseerr}";
            };
          }
          // lib.optionalAttrs homelabDeluge {
            "deluge.home.arpa".locations."/" = {
              proxyPass = "http://127.0.0.1:${toString ports.delugeWeb}";
            };
          };
      };
    };

    systemd.services = let
      mediaMountExists = builtins.hasAttr "/mnt/chonk" config.fileSystems;
      withMediaMount.serviceConfig.RequiresMountsFor = ["/mnt/chonk"];
    in {
      jellyfin = mkIf (config.services.jellyfin.enable && srvMountExists) withSrvMount;
      seerr = mkIf (config.services.seerr.enable && mediaMountExists) withMediaMount;
      prowlarr = mkIf (config.services.prowlarr.enable && mediaMountExists) withMediaMount;
      sonarr = mkIf (config.services.sonarr.enable && mediaMountExists) withMediaMount;
      radarr = mkIf (config.services.radarr.enable && mediaMountExists) withMediaMount;
      lidarr = mkIf (config.services.lidarr.enable && mediaMountExists) withMediaMount;
      bazarr = mkIf (config.services.bazarr.enable && mediaMountExists) withMediaMount;
      readarr = mkIf (config.services.readarr.enable && mediaMountExists) withMediaMount;
    };
  };
}
