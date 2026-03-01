{
  nix-config,
  config,
  pkgs,
  lib,
  ...
}: let
  desktopEnabled = builtins.elem "desktop" config.modules.system.roles;
  opacity = 0.95;
  fontSize = 13;
in {
  imports = with nix-config.inputs.stylix.nixosModules; [stylix];

  config = {
    stylix = {
      enable = true;
      autoEnable = desktopEnabled;
      imageScalingMode = "fill";
      polarity = "dark";

      image = pkgs.fetchurl {
        url = "https://i.postimg.cc/0NyngmdF/5120x2160-Monstera.png";
        sha256 = "sha256-XjOKKMQKzyfiT+CrLGjExpYGu7/AVRk/inBp+xDJG3o=";
      };

      #base16Scheme = "${pkgs.base16-schemes}/share/themes/materia.yaml";
      #polarity = "dark";
      #      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

      base16Scheme = {
        system = "base16";
        name = "everforest-dark-hard";
        author = "sainnhe";
        variant = "dark";

        palette = {
          base00 = "0F1411";
          base01 = "162019";
          base02 = "1F2D24";
          base03 = "4D6656";
          base04 = "6F8A78";
          base05 = "BFD3C0";
          base06 = "D5E5D6";
          base07 = "EDF7EE";
          base08 = "D87174";
          base09 = "C98A5A";
          base0A = "B8A15A";
          base0B = "7FB27F";
          base0C = "6D9E74";
          base0D = "8FBF72";
          base0E = "9A8BC6";
          base0F = "6F8A78";
        };
      };

      opacity = {
        terminal = opacity;
        popups = opacity + 2.5e-2;
      };

      icons = {
        enable = true;
        package = pkgs.adwaita-icon-theme;
        light = "Adwaita";
        dark = "Adwaita-dark";
      };

      cursor = {
        package = pkgs.catppuccin-cursors.mochaBlue;
        name = "catppuccin-mocha-blue-cursors";
        size = 32;
      };

      fonts = {
        serif = {
          package = pkgs.nerd-fonts.mononoki;
          name = "Mononoki Nerd Font";
        };

        sansSerif = {
          package = pkgs.nerd-fonts.iosevka;
          name = "Iosevka Nerd Font";
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
      targets = {
        console.enable = true;
      };
    };
  };
}
