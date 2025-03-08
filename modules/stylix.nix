{
  nix-config,
  pkgs,
  ...
}:

let
  opacity = 0.95;
  fontSize = 11;
in
{
  imports = with nix-config.inputs.stylix.nixosModules; [ stylix ];
  environment.systemPackages = with pkgs; [
    gtk3
  ];
  stylix = {
      enable = true;
      autoEnable = true;
      #image = "${stylix-background}/wallpaper.png";
      image = pkgs.fetchurl {
    url = "https://www.pixelstalk.net/wp-content/uploads/2016/05/Epic-Anime-Awesome-Wallpapers.jpg";
    sha256 = "enQo3wqhgf0FEPHj2coOCvo7DuZv+x5rL/WIo4qPI50=";
  };
      polarity = "dark";
        base16Scheme = {
        system = "base16";
        name = "selenized-black";
        author = "Jan Warchol (https://github.com/jan-warchol/selenized) / adapted to base16 by ali";
        variant = "dark";

        palette = {
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
          name = "Mononoki Nerd Font Propo";
        };

        sansSerif = {
          package = pkgs.nerd-fonts.iosevka;
          name = "Iosevka Nerd Font Propo";
        };

        monospace = {
          package = pkgs.nerd-fonts.iosevka-term;
          name = "Iosevka Terminal Nerd Font";
        };

        emoji = {
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };

        sizes = {
          applications = fontSize;
          desktop = fontSize - 1;
          popups = fontSize - 2;
          terminal = fontSize + 1;
        };
      };
  };
}
