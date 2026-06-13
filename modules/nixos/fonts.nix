{
  pkgs,
  config,
  lib,
  ...
}: let
  stylixFonts = config.stylix.fonts;
  cjkSansFonts = [
    "Noto Sans CJK SC"
    "Noto Sans CJK TC"
    "Noto Sans CJK JP"
  ];
  cjkSerifFonts = [
    "Noto Serif CJK SC"
    "Noto Serif CJK TC"
    "Noto Serif CJK JP"
  ];
in
  lib.mkIf config.modules.desktop.enable {
    fonts = {
      enableDefaultPackages = false;
      packages = with pkgs; [
        roboto-serif
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
      ];

      fontconfig = {
        defaultFonts = {
          serif = [stylixFonts.serif.name] ++ cjkSerifFonts;
          sansSerif = [stylixFonts.sansSerif.name] ++ cjkSansFonts;
          monospace = [stylixFonts.monospace.name] ++ cjkSansFonts;
        };
        allowBitmaps = false;
      };
    };
  }
