{
  pkgs,
  config,
  lib,
  ...
}: let
  stylixFonts = config.stylix.fonts;
in
  lib.mkIf config.modules.desktop.enable {
    fonts = {
      enableDefaultPackages = false;
      packages = with pkgs; [roboto-serif];

      fontconfig = {
        defaultFonts = {
          serif = [stylixFonts.serif.name];
          sansSerif = [stylixFonts.sansSerif.name];
          monospace = [stylixFonts.monospace.name];
        };
        allowBitmaps = false;
      };
    };
  }
