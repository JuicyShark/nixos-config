{
  self,
  pkgs,
  ...
}: let
  inherit (builtins) attrValues;
in {
  imports = attrValues self.nixosModules;
  nixpkgs.overlays = attrValues self.overlays;
  home-manager.sharedModules = attrValues self.homeModules;
  environment.systemPackages = attrValues self.packages.${pkgs.system};

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
  modules = {
    hardware = {
      bluetooth = true;
      nvidia.enable = true;
    };

    system = {
      mullvad = false;
      iHaveLotsOfRam = true;
      #postgres = true;
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
