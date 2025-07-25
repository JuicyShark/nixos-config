{
  inputs,
  nix-config,
  config,
  pkgs,
  ...
}:
let
  inherit (builtins) attrValues;
in
{
  imports = attrValues nix-config.nixosModules;
  home-manager.sharedModules = attrValues nix-config.homeModules;
  environment.systemPackages = attrValues nix-config.packages.${pkgs.system};
  environment.sessionVariables.FLAKE = "/mnt/chonk/nixos-config";
  networking.firewall.allowedTCPPorts = [
    8123
    8521
    8686
    9050
    3456
    2283
    8008
    80
    445
  ];
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "weekly";
    randomizedDelaySec = "45min";
  };
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
        "juicy"
        config.services.jellyfin.user
        config.services.deluge.user
        config.services.transmission.user
        config.services.immich.user
        config.services.sonarr.user
        config.services.radarr.user
        config.services.lidarr.user
        config.services.bazarr.user
      ];
    };
    users.media = {
      isSystemUser = true;
      group = "media";
    };
  };

  services = {
    mullvad-vpn.enable = true;
    # jmusicbot.enable = true;

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
      enable = false;
      host = "192.168.1.60";
      user = "media";
      group = "media";
      port = 2283;
      mediaLocation = "/srv/chonk/media/immich";
      machine-learning.enable = true;
      redis.enable = true;
      openFirewall = true;
    };

    jellyfin = {
      enable = true;
      user = "media";
      group = "media";
      openFirewall = true;
    };

    transmission = {
      enable = true;

      user = "media";
      group = "media";
      openFirewall = true;

      settings = {
        incomplete-dir-enabled = true;
        incomplete-dir = "/srv/chonk/media/torrent/downloading";
        download-dir = "/srv/chonk/media/torrent/data";
      };
    };
    deluge = {
      enable = true;
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
        max_active_limit = 100;
        max_active_downloading = 6;
        max_connections_global = 350;
        max_upload_speed = 1250;
        max_download_speed = 3750;
        share_ratio_limit = 2;
        allow_remote = true;
        daemon_port = 58846;
        random_port = false;
        outgoing_interface = "wg0-mullvad";
      };

      web = {
        enable = true;
        port = 9050;
        openFirewall = true;
      };
    };

    jellyseerr = {
      enable = true;
      port = 5055;
      openFirewall = true;
    };
    # Subtitles
    bazarr = {
      enable = true;
      user = "media";
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
      user = "media";
      group = "media";
      openFirewall = true;
    };
    # Movies
    radarr = {
      enable = true;
      user = "media";
      group = "media";
      openFirewall = true;
    };
    # Music
    lidarr = {
      enable = true;
      user = "media";
      group = "media";
      openFirewall = true;
    };

    matrix-synapse = {
      enable = true;
      enableRegistrationScript = true;

      settings = {
        server_name = "nixlab.au";
        public_baseurl = "https://matrix.nixlab.au";

        enable_registration = true;
        enable_registration_without_verification = true;
        #registration_shared_secrets = "gyQzMwGb97tMgKsalrjSxBB1UnKWzhs5hbXyQbNK7kD0kq7b44foIYakCaHabjVY";

        listeners = [
          {
            port = 8008;
            bind_addresses = [
              "192.168.1.60"
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

    # Network Share
    gvfs.enable = true;
    samba = {
      enable = true;
      settings = {
        global = {
          "workgroup" = "nixlab.au";
          "server string" = "smbnix";
          "netbios name" = "smbnix";
          "security" = "user";
          #"use sendfile" = "yes";
          #"max protocol" = "smb2";
          # note: localhost is the ipv6 localhost ::1
          "hosts allow" = "192.168.1. 192.168.1.54 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
          "passwd program" = "/run/wrappers/bin/passwd %u";
        };
        "public" = {
          "path" = "/srv/public";
          "browseable" = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        "chonk" = {
          "path" = "/srv/chonk/";
          "browseable" = "yes";
          "read only" = "no";
          "guest ok" = "no";
          #"create mask" = "0644";
          #"directory mask" = "0755";
          "force user" = "juicy";
          #"force group" = "users";
        };
      };
    };
    samba-wsdd = {
      enable = true;
      openFirewall = true;
      discovery = true;
      workgroup = "nixlab.au";

    };
  };

}
