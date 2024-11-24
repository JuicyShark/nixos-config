{
  nix-config,
  pkgs,
  ...
}: let
  inherit (builtins) attrValues;
in {
  imports = attrValues nix-config.nixosModules;
  nixpkgs.overlays = attrValues nix-config.overlays;
  home-manager.sharedModules = attrValues nix-config.homeModules;
  environment.systemPackages = attrValues nix-config.packages.${pkgs.system};


  modules = {
    hardware = {
      bluetooth = true;
      nvidia.enable = true;
    };

    system = {
      mullvad = false;
      iHaveLotsOfRam = true;
      username = "juicy";
      hostName = "leo";
      hashedPassword = "$y$j9T$j5oMkFeAEFqm.TmI9Yql/0$nMZGLBa0Y5E2ORwPbIr1oHVUS2jZJUjFjPPWP.SAmR8";
    };

    desktop = {
      bloat = true;
      gaming = true;
      streaming = true;
    };
  };
}
