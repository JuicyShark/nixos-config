{
  inputs,
  system,
  pkgs,
  lib,
  ...
}: let
  opacity = 0.95;
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

        base16Scheme = {
          system = "base16";
          name = "everforest-dark-hard";
          author = "sainnhe";
          variant = "dark";

          palette = {
            base00 = "0D120E";
            base01 = "131D16";
            base02 = "1A2B1F";
            base03 = "32653E";
            base04 = "6F8A78";
            base05 = "BFD3C0";
            base06 = "D5E5D6";
            base07 = "EDF7EE";
            base08 = "D87174";
            base09 = "C98A5A";
            base0A = "B8A15A";
            base0B = "7FB27F";
            base0C = "4D8B5E";
            base0D = "1AAF4F";
            base0E = "4A7B5C";
            base0F = "6F8A78";
          };
        };

        opacity = {
          terminal = opacity;
          popups = opacity + 2.5e-2;
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
            applications = fontSize - 2;
            desktop = fontSize - 1;
            popups = fontSize - 2;
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
