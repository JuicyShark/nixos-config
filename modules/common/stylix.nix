{
  inputs,
  system,
  pkgs,
  lib,
  ...
}: let
  terminalOpacity = 1.0;
  fontSize = 13;
  isLinux = lib.hasSuffix "-linux" system;

  stylixModule =
    if isLinux
    then inputs.stylix.nixosModules.stylix
    else inputs.stylix.darwinModules.stylix;
in {
  imports = [stylixModule];

  config = {
    stylix =
      {
        enable = true;
        autoEnable = true;
        imageScalingMode = "fill";
        polarity = "dark";

        image = pkgs.fetchurl {
          url = "https://i.postimg.cc/0NyngmdF/5120x2160-Monstera.png";
          sha256 = "sha256-XjOKKMQKzyfiT+CrLGjExpYGu7/AVRk/inBp+xDJG3o=";
        };

        base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";

        opacity = {
          terminal = terminalOpacity;
          popups = 1.0;
        };

        fonts = {
          serif = {
            package = pkgs.nerd-fonts.mononoki;
            name = "Mononoki Nerd Font";
          };

          sansSerif = {
            package = pkgs.atkinson-hyperlegible;
            name = "Atkinson Hyperlegible";
          };

          monospace = {
            package = pkgs.nerd-fonts.iosevka-term;
            name = "IosevkaTerm Nerd Font Mono";
          };

          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Emoji";
          };

          sizes = {
            applications = fontSize - 1;
            desktop = fontSize;
            popups = fontSize - 1;
            terminal = fontSize;
          };
        };
      }
      // lib.optionalAttrs isLinux {
        targets.console.enable = true;

        icons = {
          enable = true;
          package = pkgs.adwaita-icon-theme;
          light = "Adwaita";
          dark = "Adwaita-dark";
        };
        cursor = {
          package = pkgs.catppuccin-cursors.mochaGreen;
          name = "catppuccin-mocha-green-cursors";
          size = 36;
        };
      };
  };
}
