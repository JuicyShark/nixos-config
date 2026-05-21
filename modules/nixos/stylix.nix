{
  inputs,
  system,
  config,
  pkgs,
  lib,
  ...
}: let
  desktopEnabled = config.modules.desktop.enable or false;
  opacity = 0.95;
  fontSize = 13;
  # Must use `system` (a specialArg) rather than pkgs.stdenv here because
  # imports are resolved before config/pkgs are available.
  isLinux = lib.hasSuffix "-linux" system;
  # Must use `system` (not pkgs.stdenv) for imports and optionalAttrs because
  # pkgs depends on config, which causes infinite recursion when evaluated eagerly.
  stylixModule =
    if lib.hasSuffix "-darwin" system
    then inputs.stylix.darwinModules.stylix
    else inputs.stylix.nixosModules.stylix;
in {
  imports = [stylixModule];

  config = {
    stylix =
      {
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
      }
      // lib.optionalAttrs isLinux {
        targets.console.enable = true;

        # Linux-only stylix options (not present in nix-darwin's stylix module).
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
