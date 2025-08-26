{
  nix-config,
  config,
  pkgs,
  ...
}:

let
  opacity = 0.87;
  fontSize = 13;
in
{

  options.modules.desktop.baseOpacity = 0.9;
  imports = with nix-config.inputs.stylix.nixosModules; [ stylix ];

  config = {

    stylix = {
      enable = true;
      autoEnable = true;
      #image = ../assets/castle-on-a-hill.jpg;
      imageScalingMode = "fill";
      polarity = "dark";

      image = pkgs.fetchurl {
        url = "https://ultrawidewallpapers.net/wallpapers/329/highres/aishot-1399.jpg";
        sha256 = "sha256-C8COVZBDJiYWy2S4EdJKDSr/ZH2SnOv8njV/r+mrsEs=";
      };

      base16Scheme = "${pkgs.base16-schemes}/share/themes/materia.yaml";
      #polarity = "dark";
      #      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

      /*
        base16Scheme = {
          system = "base16";
          name = "selenized-black";
          author = "Jan Warchol (https://github.com/jan-warchol/selenized) / adapted to base16 by ali";
          variant = "dark";

          palette = {
            base00 = "263238";
            base01 = "2C393F";
            base02 = "37474F";
            base03 = "707880";
            base04 = "C9CCD3";
            base05 = "CDD3DE";
            base06 = "D5DBE5";
            base07 = "FFFFFF";
            base08 = "EC5F67";
            base09 = "EA9560";
            base0A = "FFCC00";
            base0B = "8BD649";
            base0C = "80CBC4";
            base0D = "89DDFF";
            base0E = "82AAFF";
            base0F = "EC5F67";
          };
        };
      */

      opacity = {
        terminal = opacity;
        popups = opacity + 2.5e-2;
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
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };

        sizes = {
          applications = fontSize - 2;
          desktop = fontSize - 1;
          popups = fontSize - 2;
          terminal = fontSize;
        };
      };
    };
  };
}
