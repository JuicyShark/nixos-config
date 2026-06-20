{
  osConfig,
  lib,
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.noctalia.homeModules.default];

  config = lib.optionalAttrs osConfig.programs.hyprland.enable {
    home.packages = [pkgs.ddcutil];

    programs.noctalia = {
      enable = true;
      settings = import ./noctalia-settings.nix;
    };

    stylix.targets.noctalia-shell.enable = true;
  };
}
