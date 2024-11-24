{
  nix-config,
  config,
  pkgs,
  ...
}:

let
  inherit (nix-config.packages.${pkgs.system}) aleo-fonts;

  stylix-background = nix-config.packages.${pkgs.system}.stylix-background.override {
    color = config.lib.stylix.colors.base00;
  };

  opacity = 0.95;
  fontSize = 11;
in
{
  imports = with nix-config.inputs.stylix.nixosModules; [ stylix ];
  stylix = {
      enable = true;
      autoEnable = false;
      image = "${stylix-background}/wallpaper.png";
      polarity = "dark";

      targets.chromium.enable = true;
      #targets.console.enable = true;
      targets.gtk.enable = true;
      #targets.nixos-icons.enable = true;
 targets.nixvim.enable = true;
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
        package = pkgs.phinger-cursors;
        name = "phinger-cursors";
        size = 32;
      };

      fonts = {
        serif = {
          package = pkgs.roboto-serif;
          name = "Roboto Serif";
        };

        sansSerif = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
        };

        monospace = {
          package = pkgs.maple-mono;
          name = "Maple Mono";
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
