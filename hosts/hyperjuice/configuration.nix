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
  environment.sessionVariables.FLAKE = "/mnt/chonk/nixos-config";

  modules = {
    router.enable = false;
    hardware = {
      bluetooth = true;
      nvidia.enable = true;
    };

    system = {
      mullvad = true;
      iHaveLotsOfRam = true;
      username = "juicy";
      hostName = "leo";

      #hashedPassword =
    };

    desktop = {
      enable = true;
      wallpapers = {
        "32:9".enable = false;
      };
      apps = {
        emacs = true;
        llm = true;
        bloat = true;
        gaming = true;
        streaming = true;
        virtual = true;
      };
    };
  };
}
