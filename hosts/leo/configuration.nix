{
  nix-config,
  config,
  pkgs,
  ...
}: let
  inherit (builtins) attrValues;
in {
  imports = attrValues nix-config.nixosModules;
  home-manager.sharedModules = attrValues nix-config.homeModules;
  environment.systemPackages = attrValues nix-config.packages.${pkgs.system};
  environment.sessionVariables.FLAKE = "/home/juicy/projects/nix-config";
    age.secrets.juicy-password = {
      file = ../../secrets/juicy-password.age;
    };
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

      hashedPassword = config.age.secrets.juicy-password.path; #"$y$j9T$j5oMkFeAEFqm.TmI9Yql/0$nMZGLBa0Y5E2ORwPbIr1oHVUS2jZJUjFjPPWP.SAmR8";
    };

    desktop = {
      enable = true;
      apps = {
        emacs = true;
        bloat = true;
        gaming = true;
        streaming = true;
      };
    };
  };
}
