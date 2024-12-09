{ nix-config, pkgs, ... }:

let
  inherit (nix-config.packages.${pkgs.system}) aleo-fonts;
in
  {
    fonts = {
      enableDefaultPackages = false;

      packages = with pkgs; [
        noto-fonts
        roboto-serif
        noto-fonts-emoji
        maple-mono
        font-awesome

        liberation_ttf
      ];

      fontconfig = {
        defaultFonts = {


          serif = ["Roboto Serif"];
          sansSerif = ["Noto Sans"];
          monospace = ["Maple Mono"];
        };

        allowBitmaps = false;
      };
    };
}
