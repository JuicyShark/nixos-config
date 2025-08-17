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
  cfgSrv = config.services;
in
{
  imports = attrValues nix-config.nixosModules;
  home-manager.sharedModules = attrValues nix-config.homeModules;
  environment.systemPackages = attrValues nix-config.packages.${pkgs.system};
  environment.sessionVariables.FLAKE = "/mnt/chonk/nix-config";

  age.secrets.juicy-password.file = ../../secrets/juicy-password.age;

  # Custom modules
  modules = {
    desktop.enable = false;
    homelab = {
      hostMonitoring = true;
      monitoring = true;
      media = false;
      vaultwarden = true;
      matrix-server = true;
    };
    system = {
      mullvad = false;
      username = "juicy";
      hostName = "zues";

      hashedPassword = config.age.secrets.juicy-password.path;
    };
  };
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  services.cloudflared = {
    enable = true;
    tunnels."3c58774d-3e30-4151-a9e3-28daf4f5f307" = {
      default = "http_status:404";

      certificateFile = "/home/juicy/.cloudflared/cert.pem";
      credentialsFile = "/home/juicy/.cloudflared/3c58774d-3e30-4151-a9e3-28daf4f5f307.json";

      # Proxy to local Addrsess's
      ingress = {
        #TODO personal website
        "nixlab.au" = {
          service = "http://leo.lan:8562";
        };

        "jellyfin.nixlab.au" = {
          service = "http://leo.lan:8096";
        };

        "request.nixlab.au" = {
          service = "http://leo.lan:5055";
        };

        "pass.nixlab.au" = {
          service = "http://zues.lan:8521";
        };

        "photos.nixlab.au" = {
          service = "http://leo.lan:2283";
        };

        "home-assist.nixlab.au" = {
          service = "http://192.168.1.50:8123";
        };
        "matrix.nixlab.au" = {
          service = "http://zues.lan:8008";
        };
      };
    };
  };
}
