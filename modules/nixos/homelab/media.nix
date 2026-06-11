{
  lib,
  config,
  ...
}: let
  inherit (lib) mkForce mkIf;

  homelabJellyfin = config.modules.homelab.jellyfin.enable;
  homelabMedia = config.modules.homelab.media.enable;

  inherit (config.modules) ports;
  username = "juicy";

  apiSecret = name: config.age.secrets.${name}.path;
  arrHostConfig = port: {
    bindAddress = "127.0.0.1";
    inherit port;
    username = "juicy";
    password._secret = apiSecret "juicy-password";
    authenticationMethod = "forms";
    authenticationRequired = "disabledForLocalAddresses";
    analyticsEnabled = true;
  };
  arrSettings = port: {
    server = {
      inherit port;
      bindaddress = "127.0.0.1";
    };
    auth = {
      method = mkForce "Forms";
      required = mkForce "DisabledForLocalAddresses";
    };
    log.analyticsEnabled = true;
  };
in {
  config = {
    nixflix = mkIf homelabMedia {
      enable = true;
      mediaDir = "/mnt/chonk/media";
      downloadsDir = "/mnt/chonk/media/torrent/data";
      stateDir = "/var/lib";
      mediaUsers = [username];
      serviceDependencies = ["mnt-chonk.mount"];
      nginx = {
        enable = true;
        domain = "home.arpa";
      };
      postgres.enable = true;
      recyclarr = {
        enable = true;
        group = "media";
        config.sonarr.sonarr = {
          quality_definition = {
            type = "series";
            preferred_ratio = 0.0;
          };
          quality_profiles = [
            {
              trash_id = "9d142234e45d6143785ac55f5a9e8dc9"; # WEB-1080p (Alternative)
              reset_unmatched_scores.enabled = true;
              min_format_score = 0;
              min_upgrade_format_score = 300;
              upgrade = {
                allowed = true;
                until_quality = "WEB 1080p";
                until_score = 500;
              };
            }
          ];
          custom_formats = [
            {
              trash_ids = [
                "47435ece6b99a0b477caf360e79ba0bb" # x265 (HD)
                "9b64dff695c2115facf1b6ea59c9bd07" # x265 (no HDR/DV)
              ];
              assign_scores_to = [
                {
                  trash_id = "9d142234e45d6143785ac55f5a9e8dc9";
                  score = 300;
                }
              ];
            }
            {
              trash_ids = [
                "15a05bc7c1a36e2b57fd628f8977e2fc" # AV1
              ];
              assign_scores_to = [
                {
                  trash_id = "9d142234e45d6143785ac55f5a9e8dc9";
                  score = 500;
                }
              ];
            }
          ];
        };
      };
      flaresolverr.enable = true;
      globals = {
        uids.seerr = 2000;
        gids = {
          media = 2000;
          seerr = 2000;
        };
      };

      downloadarr.deluge = mkIf config.services.deluge.enable {
        enable = true;
        dependencies = ["delugeweb.service"];
        port = ports.delugeWeb;
        password._secret = apiSecret "deluge-pass";
      };

      sonarr = {
        enable = true;
        group = "media";
        dataDir = "/var/lib/sonarr/";
        mediaDirs = ["/mnt/chonk/media/shows"];
        config = {
          apiKey._secret = apiSecret "sonarr-api";

          hostConfig = arrHostConfig ports.sonarr;
        };
        settings = arrSettings ports.sonarr;
      };

      radarr = {
        enable = true;
        group = "media";
        dataDir = "/var/lib/radarr/";
        config = {
          apiKey._secret = apiSecret "radarr-api";
          hostConfig = arrHostConfig ports.radarr;
        };
        settings = arrSettings ports.radarr;
      };

      lidarr = {
        enable = true;
        group = "media";
        dataDir = "/var/lib/lidarr";
        config = {
          apiKey._secret = apiSecret "lidarr-api";
          hostConfig = arrHostConfig ports.lidarr;
        };
        settings = arrSettings ports.lidarr;
      };

      prowlarr = {
        enable = true;
        group = "media";
        dataDir = "/var/lib/prowlarr";
        config = {
          apiKey._secret = apiSecret "prowlarr-api";
          hostConfig = arrHostConfig ports.prowlarr;
        };
        settings = arrSettings ports.prowlarr;
      };
    };

    age.secrets = mkIf homelabMedia {
      sonarr-api = {
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/sonarr-api";
        symlink = false;
      };
      radarr-api = {
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/radarr-api";
        symlink = false;
      };
      lidarr-api = {
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/lidarr-api";
        symlink = false;
      };
      prowlarr-api = {
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/prowlarr-api";
        symlink = false;
      };
      deluge-pass = {
        file = ../../../secrets/deluge-pass.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/deluge-pass";
        symlink = false;
      };
    };

    users.groups.media.gid = lib.mkOverride 10 2000;
    users.groups.media.members =
      [
        username
      ]
      ++ lib.optional config.services.deluge.enable config.services.deluge.user;

    services = {
      seerr = {
        enable = homelabMedia;
        port = ports.jellyseerr;
        openFirewall = false;
      };

      nginx = {
        enable = mkIf (homelabMedia || homelabJellyfin || config.services.deluge.enable) true;
        virtualHosts =
          lib.optionalAttrs homelabJellyfin {
            # Jellyfin needs WebSocket upgrade for live TV / casting
            "jellyfin.home.arpa".locations."/" = {
              proxyPass = "http://192.168.1.52:${toString ports.jellyfin}";
              extraConfig = ''
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
              '';
            };
          }
          // lib.optionalAttrs homelabMedia {
            "seerr.home.arpa".locations."/" = {
              proxyPass = "http://127.0.0.1:${toString ports.jellyseerr}";
            };
          }
          // lib.optionalAttrs config.services.deluge.enable {
            "deluge.home.arpa".locations."/" = {
              proxyPass = "http://127.0.0.1:${toString ports.delugeWeb}";
            };
          };
      };
    };
  };
}
