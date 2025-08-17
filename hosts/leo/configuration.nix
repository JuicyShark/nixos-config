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
  environment.sessionVariables.FLAKE = "/srv/chonk/nixos-config";

  age.secrets = {
    juicy-password = {
      file = ../../secrets/juicy-password.age;
    };

    prowlarr-api = {
      file = ../../secrets/prowlarr-api.age;
    };
    radarr-api = {
      file = ../../secrets/radarr-api.age;
    };
    sonarr-api = {
      file = ../../secrets/sonarr-api.age;
    };
    lidarr-api = {
      file = ../../secrets/lidarr-api.age;
    };

      bazarr-api = {
        file = ../../secrets/bazarr-api.age;
      };

  };

 services = {
    deluge.enable = true;
    jellyfin.enable = true;
    immich.enable = true;

  };

  modules = {
    hardware = {
      bluetooth = true;
      nvidia.enable = true;
    };

    system = {
      mullvad = true;
      nomad = true;
      iHaveLotsOfRam = true;
      username = "juicy";
      hostName = "leo";

      hashedPassword = config.age.secrets.juicy-password.path;
    };

    homelab = {
      media = true;
      nas = true;
      hostMonitoring = true;
      llm = true;
      immich = true;
      jellyfin = true;
      deluge = true;
    };

    desktop = {
      enable = true;
      apps = {
        emacs = true;
        bloat = true;
        gaming = true;
        streaming = true;
        sunshine = false;
        virtual = false;
      };
    };
  };
}
