{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkForce mkIf;

  homelabJellyfin = config.modules.homelab.jellyfin.enable;
  homelabMedia = config.modules.homelab.media.enable;
  jellyfinCfg = config.modules.homelab.jellyfin;

  inherit (config.modules) ports;
  username = "juicy";
  remoteJellyfin = homelabMedia && homelabJellyfin && !config.nixflix.jellyfin.enable;

  apiSecret = name: config.age.secrets.${name}.path;
  radarrUhdProfile = "64fb5f9858489bdac2af690e27c8f42f"; # UHD Bluray + WEB
  sonarrProfile = "9d142234e45d6143785ac55f5a9e8dc9"; # WEB-1080p (Alternative)
  sonarrEfficientProfile = "WEB-1080p Efficient";
  sonarrH265Profile = "WEB-1080p H265 Compact";
  sonarrAnimeProfile = "20e0fc959f1f1704bed501f23bdae76f"; # [Anime] Remux-1080p
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
in
{
  config = {
    nixflix = mkIf homelabMedia {
      enable = true;
      mediaDir = "/mnt/chonk/media";
      downloadsDir = "/mnt/chonk/media/torrent/data";
      stateDir = "/var/lib";
      mediaUsers = [ username ];
      serviceDependencies = [ "mnt-chonk.mount" ];
      nginx = {
        enable = true;
        domain = "home.arpa";
      };
      postgres.enable = true;
      recyclarr = {
        enable = true;
        group = "media";
        cleanupUnmanagedProfiles = {
          enable = true;
          managedProfiles = [
            "UHD Bluray + WEB"
            "WEB-1080p (Alternative)"
            sonarrEfficientProfile
            sonarrH265Profile
            "[Anime] Remux-1080p"
          ];
        };
        config = {
          sonarr.sonarr_anime = {
            quality_definition = {
              type = "anime";
              preferred_ratio = 0.0;
            };
            quality_profiles = [
              {
                trash_id = sonarrAnimeProfile;
                reset_unmatched_scores.enabled = true;
                min_format_score = 2000;
                min_upgrade_format_score = 1;
                upgrade = {
                  allowed = true;
                  until_quality = "Bluray 1080p";
                  until_score = 10000;
                };
                qualities = [
                  {
                    name = "Bluray 1080p";
                    qualities = [ "Bluray-1080p" ];
                  }
                  {
                    name = "WEB 1080p";
                    qualities = [
                      "HDTV-1080p"
                      "WEBRip-1080p"
                      "WEBDL-1080p"
                    ];
                  }
                  { name = "Bluray-720p"; }
                  {
                    name = "WEB 720p";
                    qualities = [
                      "HDTV-720p"
                      "WEBRip-720p"
                      "WEBDL-720p"
                    ];
                  }
                  { name = "Bluray-480p"; }
                  {
                    name = "WEB 480p";
                    qualities = [
                      "WEBRip-480p"
                      "WEBDL-480p"
                    ];
                  }
                  { name = "DVD"; }
                  { name = "SDTV"; }
                ];
              }
            ];
            custom_formats = [
              {
                trash_ids = [
                  "418f50b10f1907201b6cfdf881f467b7" # Anime Dual Audio
                ];
                assign_scores_to = [
                  {
                    trash_id = sonarrAnimeProfile;
                    score = 2000;
                  }
                ];
              }
              {
                trash_ids = [
                  "b2550eb333d27b75833e25b8c2557b38" # 10bit
                ];
                assign_scores_to = [
                  {
                    trash_id = sonarrAnimeProfile;
                    score = 101;
                  }
                ];
              }
            ];
          };
          radarr.radarr = {
            quality_definition = {
              type = "movie";
              preferred_ratio = 0.0;
            };
            quality_profiles = [
              {
                trash_id = radarrUhdProfile;
                reset_unmatched_scores.enabled = true;
                min_format_score = 0;
                min_upgrade_format_score = 1;
                upgrade = {
                  allowed = true;
                  until_quality = "Bluray-2160p";
                  until_score = 10000;
                };
              }
            ];
            custom_formats = [
              {
                trash_ids = [
                  "eecf3a857724171f968a66cb5719e152" # IMAX
                  "9f6cbff8cfe4ebbc1bde14c7b7bec0de" # IMAX Enhanced
                ];
                assign_scores_to = [
                  {
                    trash_id = radarrUhdProfile;
                    score = 5000;
                  }
                ];
              }
            ];
          };
          sonarr.sonarr = {
            quality_definition = {
              type = "series";
              preferred_ratio = 0.0;
            };
            quality_profiles = [
              {
                trash_id = sonarrProfile;
                reset_unmatched_scores.enabled = true;
                min_format_score = 0;
                min_upgrade_format_score = 300;
                upgrade = {
                  allowed = true;
                  until_quality = "WEB 1080p";
                  until_score = 500;
                };
              }
              {

                name = sonarrH265Profile;
                reset_unmatched_scores.enabled = true;
                min_format_score = 0;
                min_upgrade_format_score = 1;
                upgrade = {
                  allowed = true;
                  until_quality = "HDTV-1080p";
                  until_score = 1000;
                };
                qualities = [
                  {
                    name = "WEB 1080p";
                    qualities = [
                      "WEBRip-1080p"
                      "WEBDL-1080p"
                    ];
                  }
                  { name = "HDTV-1080p"; }
                ];
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
                    trash_id = sonarrProfile;
                    score = 300;
                  }
                  {
                    name = sonarrEfficientProfile;
                    score = 600;
                  }
                  {
                    name = sonarrH265Profile;
                    score = 1000;
                  }
                ];
              }
              {
                trash_ids = [
                  "cddfb4e32db826151d97352b8e37c648" # x264
                ];
                assign_scores_to = [
                  {
                    name = sonarrH265Profile;
                    score = 100;
                  }
                ];
              }
              {
                trash_ids = [
                  "15a05bc7c1a36e2b57fd628f8977e2fc" # AV1
                ];
                assign_scores_to = [
                  {
                    trash_id = sonarrProfile;
                    score = 500;
                  }
                  {
                    name = sonarrEfficientProfile;
                    score = 1000;
                  }
                  {
                    name = sonarrH265Profile;
                    score = 800;
                  }
                ];
              }
            ];
          };
        };
      };
      flaresolverr.enable = true;

      downloadarr.deluge = mkIf config.services.deluge.enable {
        enable = true;
        dependencies = [ "delugeweb.service" ];
        port = ports.delugeWeb;
        password._secret = apiSecret "deluge-pass";
      };

      sonarr = {
        enable = true;
        group = "media";
        dataDir = "/var/lib/sonarr/";
        mediaDirs = [ "/mnt/chonk/media/shows" ];
        config = {
          apiKey._secret = apiSecret "sonarr-api";

          hostConfig = arrHostConfig ports.sonarr;
        };
        settings = arrSettings ports.sonarr;
      };

      sonarr-anime = {
        enable = true;
        group = "media";
        dataDir = "/var/lib/sonarr-anime/";
        mediaDirs = [ "/mnt/chonk/media/anime" ];
        config = {
          apiKey._secret = apiSecret "sonarr-api";
          hostConfig = arrHostConfig 8990;
        };
        settings = arrSettings 8990;
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
          indexers = [
            {
              name = "IPTorrents";
              enable = true;
              cookie._secret = apiSecret "pirates-cookie";
              userAgent._secret = apiSecret "pirates-agent";
              freeLeechOnly = true;
            }
          ];
        };
        settings = arrSettings ports.prowlarr;
      };

      seerr = {
        enable = true;
        apiKey._secret = apiSecret "seerr-api";
        port = ports.jellyseerr;
        group = "media";
        dataDir = "/var/lib/seerr";
        jellyfin = {
          inherit (jellyfinCfg) adminUsername;
          adminPassword._secret = apiSecret "jellyfin-admin-password";
          hostname = "jellyfin.home.arpa";
          port = 80;
          externalHostname = "http://jellyfin.home.arpa";
        };
      };
    };

    age.secrets = mkIf homelabMedia {
      jellyfin-admin-password = {
        file = ../../../secrets/jellyfin-admin-password.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/jellyfin-admin-password";
        symlink = false;
      };
      seerr-api = {
        file = ../../../secrets/seerr-api.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/seerr-api";
        symlink = false;
      };
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
      pirates-cookie = {
        file = ../../../secrets/pirates-cookie.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/pirates-cookie";
        symlink = false;
      };
      pirates-agent = {
        file = ../../../secrets/pirates-agent.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/pirates-agent";
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
    users.groups.media.members = [
      username
    ]
    ++ lib.optional config.services.deluge.enable config.services.deluge.user;

    systemd.services = mkIf remoteJellyfin {
      seerr-setup.enable = mkForce false;
      seerr-user-settings.enable = mkForce false;
      seerr-jellyfin.enable = mkForce false;
      seerr-libraries.enable = mkForce false;
      seerr-radarr.enable = mkForce false;
      seerr-sonarr.enable = mkForce false;
    };

    services = {
      nginx = {
        enable = mkIf (homelabMedia || homelabJellyfin || config.services.deluge.enable) true;
        virtualHosts =
          lib.optionalAttrs homelabJellyfin {
            # Jellyfin needs WebSocket upgrade for live TV / casting
            "jellyfin.home.arpa".locations."/" = {
              proxyPass = "http://${jellyfinCfg.host}:${toString ports.jellyfin}";
              extraConfig = ''
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
              '';
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
