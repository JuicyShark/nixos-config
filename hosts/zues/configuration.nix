{
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
  environment.sessionVariables.FLAKE = "/home/juicy/nix-config";

  # Custom modules
  modules = {
    desktop.enable = false;
    system = {
      username = "juicy";
      hostName = "zues";
      hashedPassword = "$y$j9T$j5oMkFeAEFqm.TmI9Yql/0$nMZGLBa0Y5E2ORwPbIr1oHVUS2jZJUjFjPPWP.SAmR8";
    };
  };

  # Host Specific Programs

  # Host Specific Services
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
            service = "http://192.168.1.60:8521";
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
            service = "http://192.168.1.60:8199";
          };
          "home-assist.nixlab.au" = {
            service = "http://192.168.1.59:8123";
          };
          "matrix.nixlab.au" = {
            service = "http://192.168.1.60:8008";
          };
        };
      };
    };
  };

  networking = {
    defaultGateway = "192.168.1.1";
    nameservers = [ "1.1.1.1" ];
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
      #defaultGateway = "192.168.1.1";
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.1.99";
          prefixLength = 24;
        }
      ];
    };
  };

}
