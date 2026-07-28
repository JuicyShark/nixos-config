{
  lib,
  config,
  ...
}: let
  inherit (lib) mkForce mkIf;
  inherit (config.modules) ports;

  apiSecret = name: config.age.secrets.${name}.path;

  radarrUhdProfile = "64fb5f9858489bdac2af690e27c8f42f"; # UHD Bluray + WEB
  web1080p = "9d142234e45d6143785ac55f5a9e8dc9"; # WEB-1080p (Alternative)
  compressed1080p = "WEB-1080p Efficient";
  compressed720p = "Low Quality Slop";
  chineseImmersion1080p = "WEB-1080p Chinese Immersion";
  anime = "20e0fc959f1f1704bed501f23bdae76f"; # [Anime] Remux-1080p

  qualityMin = name: min: {
    inherit name min;
  };
  movieQualityMinimums = [
    (qualityMin "WEBDL-2160p" 10)
    (qualityMin "WEBRip-2160p" 10)
    (qualityMin "Bluray-2160p" 12)
    (qualityMin "WEBDL-1080p" 4)
    (qualityMin "WEBRip-1080p" 4)
    (qualityMin "Bluray-1080p" 5)
    (qualityMin "WEBDL-720p" 2)
    (qualityMin "WEBRip-720p" 2)
    (qualityMin "Bluray-720p" 3)
  ];
  seriesQualityMinimums = [
    (qualityMin "HDTV-1080p" 4)
    (qualityMin "WEBDL-1080p" 4)
    (qualityMin "WEBRip-1080p" 4)
    (qualityMin "Bluray-1080p" 5)
    (qualityMin "HDTV-720p" 2)
    (qualityMin "WEBDL-720p" 2)
    (qualityMin "WEBRip-720p" 2)
    (qualityMin "Bluray-720p" 3)
  ];

  username = config.modules.profile.username;
  arrBindAddress =
    if config.modules.homelab.media.enable
    then config.vpnNamespaces.wg.namespaceAddress
    else "127.0.0.1";

  # Shared Settings
  arrHostConfig = port: {
    inherit port username;
    bindAddress = arrBindAddress;
    password._secret = apiSecret "juicy-password";
    authenticationMethod = "forms";
    authenticationRequired = "disabledForLocalAddresses";
    analyticsEnabled = true;
  };

  # Shared Settings
  arrSettings = port: {
    server = {
      inherit port;
      bindaddress = arrBindAddress;
    };
    auth = {
      method = mkForce "Forms";
      required = mkForce "DisabledForLocalAddresses";
    };
    log.analyticsEnabled = true;
  };
in {
  config = {
    boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = mkIf config.modules.homelab.media.enable (
      mkForce 1
    );

    nixflix = mkIf config.modules.homelab.media.enable {
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
      vpn = {
        enable = true;
        wgConfFile = config.age.secrets."zues-wg".path;
        accessibleFrom = ["192.168.1.0/24"];
      };
      torrentClients.qbittorrent = {
        enable = true;
        group = "media";
        downloadsDir = "/mnt/chonk/torrent";
        subdomain = "torrent";
        serverConfig = {
          LegalNotice.Accepted = true;
          Preferences = {
            NetworkInterface = "wg-br";
            WebUI = {
              Username = username;
              Password_PBKDF2 = "@ByteArray(8jdOijrb6SqrAuw5sM3WPg==:KBC5PSh+MrkB0ucA5IjlTTWKjx/JDz9HxoU81ycAU9jjLibqYc8CJAXiT6rh6MhFOvFEJVlSS1JzUex92C+60A==)";
            };
          };
        };

        vpn.enable = true;
      };
      postgres.enable = true;
      recyclarr = {
        enable = true;
        group = "media";
        cleanupUnmanagedProfiles = {
          enable = false;
          managedProfiles = [
            "UHD Bluray + WEB" # radarrUahdProfile
            "WEB-1080p (Alternative)" # web1080p
            compressed1080p
            chineseImmersion1080p
            "[Anime] Remux-1080p" # anime
          ];
        };
        config = {
          #Sonarr radarr profile
          radarr.radarr = {
            quality_definition = {
              type = "movie";
              preferred_ratio = 0.0;
              qualities = movieQualityMinimums;
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
          # Sonarr Profiles
          sonarr.sonarr = {
            quality_definition = {
              type = "series";
              preferred_ratio = 0.0;
              qualities = seriesQualityMinimums;
            };
            quality_profiles = [
              {
                trash_id = web1080p;
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
                name = compressed1080p;
                reset_unmatched_scores.enabled = true;
                min_format_score = 0;
                min_upgrade_format_score = 150;
                upgrade = {
                  allowed = true;
                  until_quality = "HDTV-1080p";
                  until_score = 1000;
                };
                qualities = [
                  {name = "HDTV-1080p";}
                  {name = "HDTV-720p";}
                  {name = "WEBDL-1080p";}
                  {name = "WEBDL-720p";}
                  {
                    name = "LQ";
                    qualities = [
                      "WEBDL-480p"
                      "SDTV"
                      "DVD"
                    ];
                  }
                  {
                    name = "WEBRIPS";
                    qualities = [
                      "WEBRip-1080p"
                      "WEBRip-720p"
                      "WEBRip-480p"
                    ];
                  }
                ];
              }
              {
                name = compressed720p;
                reset_unmatched_scores.enabled = true;
                min_format_score = 0;
                min_upgrade_format_score = 150;
                upgrade = {
                  allowed = true;
                  until_quality = "HDTV-1080p";
                  until_score = 1000;
                };
                qualities = [
                  {name = "HDTV-720p";}
                  {name = "HDTV-1080p";}
                  {name = "WEBDL-720p";}

                  {
                    name = "LQ";
                    qualities = [
                      "WEBDL-480p"
                      "SDTV"
                      "DVD"
                    ];
                  }

                  {
                    name = "WEB";
                    qualities = [
                      "WEBRip-1080p"
                      "WEBDL-1080p"
                      "WEBRip-720p"
                      "WEBRip-480p"
                    ];
                  }
                ];
              }
              {
                name = chineseImmersion1080p;
                reset_unmatched_scores.enabled = true;
                min_format_score = 0;
                min_upgrade_format_score = 150;
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
                  {name = "HDTV-1080p";}
                ];
              }
              {
                trash_id = anime;
                reset_unmatched_scores.enabled = true;
                min_format_score = 2000;
                min_upgrade_format_score = 1;
                upgrade = {
                  allowed = true;
                  until_quality = "Bluray-1080p";
                  until_score = 10000;
                };
                qualities = [
                  {name = "Bluray-1080p";}
                  {
                    name = "WEB 1080p";
                    qualities = [
                      "HDTV-1080p"
                      "WEBRip-1080p"
                      "WEBDL-1080p"
                    ];
                  }
                  {name = "Bluray-720p";}
                  {
                    name = "WEB 720p";
                    qualities = [
                      "HDTV-720p"
                      "WEBRip-720p"
                      "WEBDL-720p"
                    ];
                  }
                  {name = "Bluray-480p";}
                  {
                    name = "WEB 480p";
                    qualities = [
                      "WEBRip-480p"
                      "WEBDL-480p"
                    ];
                  }
                  {name = "DVD";}
                  {name = "SDTV";}
                ];
              }
            ];
            custom_formats = [
              {
                trash_ids = [
                  "47435ece6b99a0b477caf360e79ba0bb" # x265 (HD)
                  #  "9b64dff695c2115facf1b6ea59c9bd07" # x265 (no HDR/DV)
                ];
                assign_scores_to = [
                  {
                    trash_id = web1080p;
                    score = mkForce 300;
                  }
                  {
                    name = compressed1080p;
                    score = 1000;
                  }
                  {
                    name = compressed720p;
                    score = 1000;
                  }
                  {
                    name = chineseImmersion1080p;
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
                    name = compressed1080p;
                    score = 100;
                  }
                  {
                    name = compressed720p;
                    score = 100;
                  }
                  {
                    name = chineseImmersion1080p;
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
                    trash_id = web1080p;
                    score = 500;
                  }
                  {
                    name = compressed1080p;
                    score = 1000;
                  }
                  {
                    name = compressed720p;
                    score = 1100;
                  }
                  {
                    name = chineseImmersion1080p;
                    score = 1000;
                  }
                ];
              }
              {
                trash_ids = [
                  "ae575f95ab639ba5d15f663bf019e3e8" # Language: Not Original
                ];
                assign_scores_to = [
                  {
                    name = chineseImmersion1080p;
                    score = -10000;
                  }
                ];
              }
              {
                trash_ids = [
                  "69aa1e159f97d860440b04cd6d590c4f" # Language: Not English
                ];
                assign_scores_to = [
                  {
                    name = chineseImmersion1080p;
                    score = 250;
                  }
                ];
              }
              {
                trash_ids = [
                  "ceb6ca558f4a3d47a00ebbdcb7fa7922" # Dual Audio Asian
                ];
                assign_scores_to = [
                  {
                    name = chineseImmersion1080p;
                    score = 800;
                  }
                ];
              }
              {
                trash_ids = [
                  "7ba05c6e0e14e793538174c679126996" # MULTi
                ];
                assign_scores_to = [
                  {
                    name = chineseImmersion1080p;
                    score = 300;
                  }
                ];
              }
              {
                trash_ids = [
                  "a69163b534969846c60b6b294e8ed7b3" # Asian Tier 01
                  "4712302767772003bfeb01d1f5f0a6fd" # Asian Tier 02
                  "0183b666f79529efb85df21b7a2cf913" # Asian Tier 03
                ];
                assign_scores_to = [
                  {
                    name = chineseImmersion1080p;
                    score = 700;
                  }
                ];
              }
              {
                trash_ids = [
                  "9a836f109fc47f7c459703c1dbafeeec" # Asian LQ
                ];
                assign_scores_to = [
                  {
                    name = chineseImmersion1080p;
                    score = -10000;
                  }
                ];
              }
              {
                trash_ids = [
                  "4c67ff059210182b59cdd41697b8cb08" # Bilibili
                  "6123bfd18480b3b0d038caaa38cfa35f" # iQIY
                  "932fafe503110be779ae49342dfad30b" # WETV
                  "e9e79cb37b02f8296976f3ed3128c8cf" # YOUKU
                  "932d0a3499cc4c529fb86e3adf1326d9" # Viki
                  "93c9d1e566dca8b34d57f5efbbf85f28" # VIU
                  "b61e27491a46c1e23bfb2f2497870495" # Hami
                  "dc44a5d07db7938a84e4401a7b5059bc" # KKTV
                  "f3e4d3733b4dce640081977b8c500f19" # LINETV
                  "6e14bcd243960ebe991e475ab86fd44e" # MyTVSuper
                ];
                assign_scores_to = [
                  {
                    name = chineseImmersion1080p;
                    score = 300;
                  }
                ];
              }
              {
                trash_ids = [
                  "418f50b10f1907201b6cfdf881f467b7" # Anime Dual Audio
                ];
                assign_scores_to = [
                  {
                    trash_id = anime;
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
                    trash_id = anime;
                    score = 100;
                  }
                  {
                    trash_id = web1080p;
                    score = 100;
                  }
                  {
                    name = compressed1080p;
                    score = 100;
                  }
                  {
                    name = compressed720p;
                    score = 100;
                  }
                ];
              }
            ];
          };
        };
      };
      flaresolverr.enable = true;

      downloadarr = {
        qbittorrent = {
          enable = true;
          password._secret = apiSecret "qbit";
        };
      };
      sonarr = {
        enable = true;
        vpn.enable = true;
        group = "media";
        dataDir = "/var/lib/sonarr/";
        mediaDirs = [
          "/mnt/chonk/media/shows"
          #"/mnt/chonk/media/anime"
        ];
        config = {
          apiKey._secret = apiSecret "sonarr-api";
          hostConfig = arrHostConfig ports.sonarr;
        };
        settings = arrSettings ports.sonarr;
      };

      radarr = {
        enable = true;
        vpn.enable = true;
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
        vpn.enable = true;
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
        vpn.enable = true;
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
              freeLeechOnly = false;
              priority = 25;
            }
            {
              name = "IPTorrents (freeleech)";
              schemaName = "IPTorrents";
              enable = true;
              cookie._secret = apiSecret "pirates-cookie";
              userAgent._secret = apiSecret "pirates-agent";
              freeLeechOnly = true;
              priority = 15;
            }

            {
              name = "Nyaa.si";
              enable = true;
              priority = 25;
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
          adminUsername = username;
          adminPassword._secret = apiSecret "jellyfin-admin-password";
          hostname = "jellyfin.home.arpa";
          port = 80;
          externalHostname = "https://jellyfin.nixlab.au";
        };
      };
    };

    age.secrets = mkIf config.modules.homelab.media.enable {
      "zues-wg" = {
        file = ../../../secrets/zues-wg.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
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
      qbit = {
        file = ../../../secrets/qbit.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/qbit-pass";
        symlink = false;
      };
    };

    users.groups.media.gid = lib.mkOverride 10 2000;
    users.groups.media.members = [username];

    systemd.services = mkIf (!config.nixflix.jellyfin.enable) {
      seerr-setup.enable = mkForce false;
      seerr-user-settings.enable = mkForce false;
      seerr-jellyfin.enable = mkForce false;
      seerr-libraries.enable = mkForce false;
      seerr-radarr.enable = mkForce false;
      seerr-sonarr.enable = mkForce false;
    };

    services = {
      transmission.enable = mkForce false;

      nginx = {
        enable = mkIf config.modules.homelab.media.enable true;
        virtualHosts."jellyfin.home.arpa".locations."/" = {
          proxyPass = "http://192.168.1.52:${toString ports.jellyfin}";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };
    };
  };
}
