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
  environment.sessionVariables.FLAKE = "/home/juicy/nix-config";

  modules = {
    router.enable = true;
    desktop.enable = false;
    system = {
      username = "juicy";
      hostName = "zues";
      hashedPassword = "$y$j9T$j5oMkFeAEFqm.TmI9Yql/0$nMZGLBa0Y5E2ORwPbIr1oHVUS2jZJUjFjPPWP.SAmR8";
    };
  };
}
