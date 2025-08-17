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
      enable = false;
      autoEnable = true;
      # image = "/home/juicy/media/pictures/wallpaper/UltrawideWallpapersDotNet-997.png";
      imageScalingMode = "fill";
      polarity = "dark";
      image = pkgs.fetchurl {
        url = "https://ultrawidewallpapers.net/wallpapers/329/highres/aishot-997.jpg";
        sha256 = "sha256-vep9AKzwnS4s4dN9t1Jnd08N8wnJ1U92QAJW10RdSSM=";
      };
      #base16Scheme = "${pkgs.base16-schemes}/share/themes/materia.yaml";
      #polarity = "dark";
      #      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

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
          /*
            # outrun dark
            base00 = "00002A";
            base01 = "20204A";
            base02 = "30305A";
            base03 = "50507A";
            base04 = "B0B0DA";
            base05 = "D0D0FA";
            base06 = "E0E0FF";
            base07 = "F5F5FF";
            base08 = "FF4242";
            base09 = "FC8D28";
            base0A = "F3E877";
            base0B = "59F176";
            base0C = "0EF0F0";
            base0D = "66B0FF";
            base0E = "F10596";
            base0F = "F003EF";
          */
          /*
            # catpuccin
             base00 = "1e1e2e";
             base01 = "181825";
             base02 = "313244";
             base03 = "45475a";
             base04 = "585b70";
             base05 = "cdd6f4";
             base06 = "f5e0dc";
             base07 = "b4befe";
             base08 = "f38ba8";
             base09 = "fab387";
             base0A = "f9e2af";
             base0B = "a6e3a1";
             base0C = "94e2d5";
             base0D = "89b4fa";
             base0E = "cba6f7";
             base0F = "f2cdcd";
          */
        };
      };

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
