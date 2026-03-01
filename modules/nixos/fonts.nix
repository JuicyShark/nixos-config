{
  pkgs,
  config,
  lib,
  ...
}:
lib.mkIf (builtins.elem "desktop" config.modules.system.roles) {
  fonts = {
    enableDefaultPackages = false;
    packages = with pkgs; [roboto-serif];

    fontconfig = {
      defaultFonts = {
        serif = ["Mononoki Nerd Font"];
        sansSerif = ["Iosevka Nerd Font"];
        monospace = ["IosevkaTerm Nerd Font Mono"];
      };
      allowBitmaps = false;
    };
  };
}
