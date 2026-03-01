{
  nix-config,
  config,
  ...
}:
let
  inherit (builtins) attrValues;
  networkCfg = config.modules.network;
in
{
  imports = with nix-config.nixosModules; [
    system
    shell
    homelab
    filebrowser
    monitoring
    glance
    unbound
    network
    nfs
  ];
  home-manager.sharedModules = attrValues nix-config.homeModules;
  environment.sessionVariables.FLAKE = "/mnt/chonk/nix-config";

  system.autoUpgrade = {
    enable = true;
    flake = "/mnt/chonk/nix-config";
    dates = "Sun 04:00";
    randomizedDelaySec = "45min";
    persistent = true;
    operation = "switch";
    allowReboot = false;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L"
    ];
  };

  modules = {
    system = {
      roles = [
        "homelab-filebrowser"
        "homelab-deluge"
        "homelab-host-monitoring"
        "homelab-jellyfin"
        "homelab-media"
        "homelab-monitoring"
        "homelab-vaultwarden"
      ];
      username = "juicy";
      hostName = "zues";
      hashedPasswordFile = config.age.secrets.juicy-password.path;
    };
    homelab = {
      smtpEmail = "maxwellb9879@gmail.com";
    };
    nfs = {
      exportPath = "/srv/chonk";
    };
  };

  networking.firewall.interfaces = {
    br0 = {
      allowedTCPPorts = [
        445
        5357
        5358
      ];
      allowedUDPPorts = [
        3702
        5353
      ];
    };
    tailscale0.allowedTCPPorts = [ 445 ];
  };

  services = {
    cloudflared = {
      enable = true;
      tunnels."3c58774d-3e30-4151-a9e3-28daf4f5f307" = {
        default = "http_status:404";

        certificateFile = "/home/juicy/.cloudflared/cert.pem";
        credentialsFile = "/home/juicy/.cloudflared/3c58774d-3e30-4151-a9e3-28daf4f5f307.json";

        # Proxy to local Addrsess's
        ingress = {
          # WANT add personal website ingress
          "nixlab.au" = {
            service = "http://192.168.1.54:3457";
          };

          "pass.nixlab.au" = {
            service = "http://192.168.1.99:8521";
          };
          "jellyfin.nixlab.au" = {
            service = "http://192.168.1.52:8096";
          };
        };
      };
    };

    nginx = {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;

      virtualHosts = {
        "zues.home.arpa" = {
          locations."/" = {
            extraConfig = ''
              return 302 http://grafana.home.arpa;
            '';
          };
        };
        "grafana.home.arpa" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
          };
        };
        "prometheus.home.arpa" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:9090";
          };
        };
        "alertmanager.home.arpa" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:9093";
          };
        };
        "loki.home.arpa" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:3100";
          };
        };
        "jellyfin.home.arpa" = {
          locations."/" = {
            proxyPass = "http://192.168.1.52:8096";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            '';
          };
        };

        "vaultwarden.home.arpa" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:8521";
          };
        };
        "files.home.arpa" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:8095";
          };
        };
      };
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      allowInterfaces = [ "br0" ];
      openFirewall = false;
      publish = {
        enable = true;
        userServices = true;
      };
    };

    samba = {
      enable = true;
      openFirewall = false;
      settings = {
        global = {
          "server min protocol" = "SMB2";
          "disable netbios" = "yes";
          "smb ports" = "445";
          "interfaces" = "lo br0 tailscale0";
          "bind interfaces only" = "yes";
          "hosts allow" = "127. ${networkCfg.subnets.lan} 100.64.0.0/10";
          "hosts deny" = "0.0.0.0/0";
          "map to guest" = "Bad User";
          "guest account" = "nobody";
        };

        FamilyShared = {
          path = "/srv/chonk/family/Shared";
          "browseable" = "yes";
          "read only" = "yes";
          "guest ok" = "yes";
          "force user" = "media";
          "force group" = "media";
          "create mask" = "0664";
          "directory mask" = "0775";
        };

        FamilyUploads = {
          path = "/srv/chonk/family/Uploads";
          "browseable" = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "force user" = "media";
          "force group" = "media";
          "create mask" = "0664";
          "directory mask" = "0775";
        };
      };
    };

    samba-wsdd = {
      enable = true;
      interface = "br0";
      openFirewall = false;
    };

    restic.backups.family-share = {
      initialize = true;
      repository = "/srv/chonk/backups/restic-family";
      passwordFile = "/var/lib/restic-family/password";
      paths = [ "/srv/chonk/family" ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "1h";
        Persistent = true;
      };
      backupPrepareCommand = ''
        install -d -m 0700 /var/lib/restic-family
        if [ ! -s /var/lib/restic-family/password ]; then
          umask 0077
          tr -dc 'A-Za-z0-9!@#$%^&*()-_=+[]{}' </dev/urandom | head -c 48 > /var/lib/restic-family/password
        fi
      '';
    };
    # Personal VPN
    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "both";
      extraUpFlags = [
        "--advertise-routes=192.168.1.0/24"
        "--accept-dns=false"
      ];
    };
    # Cached DNS
    unbound = {
      enable = true;
      localControlSocketPath = "/run/unbound/unbound.ctl";

      settings = {
        server = {
          interface = [
            "127.0.0.1@5353"
          ];
          access-control = [
            "127.0.0.0/8 allow"
            "${networkCfg.subnets.lan} allow"
          ];
          verbosity = 1;
        };
        forward-zone = [
          {
            name = ".";
            forward-addr = [
              "1.1.1.1"
              "1.0.0.1"
            ];
          }
        ];
      };
    };

    # Base DNS
    dnsmasq = {
      enable = true;
      alwaysKeepRunning = true;
      resolveLocalQueries = true;

      settings = {
        no-resolv = true;
        # General
        listen-address = [
          "192.168.1.99"
          "127.0.0.1"
        ];
        server = [ "127.0.0.1#5353" ];
        #cache-size = 1000;

        domain-needed = true;
        bogus-priv = true;

        # Domain
        domain = "home.arpa";
        local = "/home.arpa/";
        localise-queries = true;

        interface = [
          "br0"
        ];

        except-interface = "enp1s0";
        bind-interfaces = true;
        expand-hosts = true;

        dhcp-ignore-names = true;
        dhcp-option = [
          "3,192.168.1.99"
          "6,192.168.1.99"
          "15,home.arpa"
        ];
        dhcp-range = [
          "192.168.1.10,192.168.1.98,12h"
          "192.168.1.100,192.168.1.199,24h"
          "192.168.1.200,192.168.1.254,24h"
        ];
        dhcp-host = [
          "D8:5E:D3:AF:EE:02,machop,set:machop,192.168.1.54"
          "86:22:d4:1a:f8:0c,machop-iphone,192.168.1.53"
          "D0:11:E5:9A:85:20,imac-machop,192.168.1.52"

          "34:C9:3D:1E:4C:1D,quagsire-laptop,192.168.1.120"

          "D8:BB:C1:92:7B:1D,viridian,192.168.1.150"
          "04:E4:B6:13:C0:EC,viridian-monitor,192.168.1.152"

          "5C:84:3C:69:14:11,evee-ps5,192.168.1.230"

          # Smart Home
          "68:FE:71:A5:36:38,wled-double,192.168.1.12"
          "78:42:1C:F2:79:1C,big-grow-light-plug,192.168.1.18"
          "78:42:1C:F2:79:7E,smart-plug2,192.168.1.19"
        ];

        address = [
          # local services

          "/router/192.168.1.99"
          "/router.home.arpa/192.168.1.99"
          "/grafana.home.arpa/192.168.1.99"
          "/prometheus.home.arpa/192.168.1.99"
          "/alertmanager.home.arpa/192.168.1.99"
          "/loki.home.arpa/192.168.1.99"
          "/jellyfin.home.arpa/192.168.1.99"
          "/vaultwarden.home.arpa/192.168.1.99"
          "/files.home.arpa/192.168.1.99"
          #"/ap-1/192.168.1.1"

          "/dante/192.168.1.60"
          "/leo/192.168.1.54"
          "/leo.home.arpa/192.168.1.54"
          "/zues/192.168.1.99"
          "/zues.home.arpa/192.168.1.99"
          "/hermes/192.168.1.56"
        ];
      };
    };
  };

  systemd.services = {
    samba-smbd.serviceConfig.RequiresMountsFor = [ "/srv/chonk" ];
    restic-backups-family-share.serviceConfig.RequiresMountsFor = [ "/srv/chonk" ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/chonk/backups 0750 media media -"
    "d /srv/chonk/backups/restic-family 0750 media media -"
    "d /var/lib/restic-family 0700 root root -"
  ];
}
