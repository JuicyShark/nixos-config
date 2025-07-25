{
  inputs,
  nix-config,
  config,
  lib,
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
  environment.sessionVariables.FLAKE = "/mnt/chonk/nix-config";

  # Custom modules
  modules = {
    desktop.enable = false;
    system = {
      mullvad = false;
      username = "juicy";
      hostName = "zues";
      hashedPassword = "$y$j9T$j5oMkFeAEFqm.TmI9Yql/0$nMZGLBa0Y5E2ORwPbIr1oHVUS2jZJUjFjPPWP.SAmR8";
    };
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
          "nixlab.au" = {
            service = "http://192.168.1.60:8562";
          };
          # Jellyfin
          "jellyfin.nixlab.au" = {
            service = "http://192.168.1.60:8096";
          };
          "request.nixlab.au" = {
            service = "http://192.168.1.60:5055";
          };
          # Vaultwarden
          "pass.nixlab.au" = {
            service = "http://192.168.1.99:8521";
          };

          # Vikunja
          "tasks.nixlab.au" = {
            service = "http://192.168.1.60:3456";
          };
          "photos.nixlab.au" = {
            service = "http://192.168.1.60:2283";
          };
          "mail.nixlab.au" = {
            service = "http_status:404";
          };
          "git.nixlab.au" = {
            service = "http://192.168.1.99:8199";
          };
          "home-assist.nixlab.au" = {
            service = "http://192.168.1.59:8123";
          };
          "matrix.nixlab.au" = {
            service = "http://192.168.1.99:8008";
          };
        };
      };
    };
  };

  networking = {
    useDHCP = lib.mkForce false;
    wireless.enable = false;

    firewall.trustedInterfaces = [ "br0" ];

    bridges = {
      br0 = {
        interfaces = [
          "enp1s0"
          "enp2s0"
          "enp3s0"
          "enp4s0"
        ];
      };
    };

    interfaces.br0 = {
      useDHCP = true;
      ipv4.addresses = [
        {
          address = "192.168.1.99";
          prefixLength = 24;
        }
      ];
    };
  };

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

  users = {
    groups.media = {
      name = "media";
      members = [
        "juicy"
      ];
    };
    users.media = {
      isSystemUser = true;
      group = "media";
    };
  };

  services = {
    vaultwarden = {
      enable = true;
      config = {
        DOMAIN = "https://pass.nixlab.au";
        SIGNUPS_ALLOWED = true;
        ROCKET_ADDRESS = "192.168.1.99";
        ROCKET_PORT = "8521";
        WEB_VAULT_ENABLED = true;
      };
    };

    jellyseerr = {
      enable = true;
      port = 5055;
      openFirewall = true;
    };

    matrix-synapse = {
      enable = false;
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
  };
}
