{
  inputs,
  nix-config,
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
    homelab = {
      hostMonitoring = true;
      monitoring = true;
      media = true;

    };
    system = {
      mullvad = false;
      username = "juicy";
      hostName = "zues";
      hashedPassword = "$y$j9T$j5oMkFeAEFqm.TmI9Yql/0$nMZGLBa0Y5E2ORwPbIr1oHVUS2jZJUjFjPPWP.SAmR8";
    };
  };
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
  # systemd.services.unbound.serviceConfig.ReadWritePaths = [ "/var/lib/unbound" ];
  services = {
    nomad.settings.server.enabled = true;
    vaultwarden.enable = true;
    #adguardhome.enable = true;


    cloudflared = {
      enable = true;

      tunnels."3c58774d-3e30-4151-a9e3-28daf4f5f307" = {
        default = "http_status:404";

        certificateFile = "/home/juicy/.cloudflared/cert.pem";
        credentialsFile = "/home/juicy/.cloudflared/3c58774d-3e30-4151-a9e3-28daf4f5f307.json";

        # Proxy to local Addrsess's
        ingress = {
          "nixlab.au" = {
            service = "http://192.168.1.54:8562";
          };
          "jellyfin.nixlab.au" = {
            service = "http://192.168.1.54:8096";
          };
          "request.nixlab.au" = {
            service = "http://192.168.1.99:5055";
          };
          "pass.nixlab.au" = {
            service = "http://192.168.1.99:8521";
          };

          "photos.nixlab.au" = {
            service = "http://192.168.1.54:2283";
          };
          # TODO setup mailserver
          "mail.nixlab.au" = {
            service = "http_status:404";
          };

          "git.nixlab.au" = {
            service = "http://192.168.1.54:8199";
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
              "192.168.1.99"
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
