{
  inputs,
  system,
  pkgs,
  lib,
  ...
}: let
  # Subtle wallpaper/blur without washing out terminal text.
  terminalOpacity = 0.94;
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
        imageScalingMode = "fill";
        polarity = "dark";

        image = pkgs.fetchurl {
          url = "https://i.postimg.cc/0NyngmdF/5120x2160-Monstera.png";
          sha256 = "sha256-XjOKKMQKzyfiT+CrLGjExpYGu7/AVRk/inBp+xDJG3o=";
        };

        # Read the already-pinned theme source without a platform-specific build.
        base16Scheme = "${inputs.stylix.inputs.tinted-schemes}/base16/kanagawa.yaml";

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
        # Noctalia owns the greetd UI; avoid Stylix's unused ReGreet target.
        targets.regreet.enable = false;

        icons = {
          enable = true;
          package = pkgs.papirus-icon-theme;
          light = "Papirus-Light";
          dark = "Papirus-Dark";
        };
        cursor = {
          package = pkgs.catppuccin-cursors.mochaGreen;
          name = "catppuccin-mocha-green-cursors";
          size = 36;
        };
      };
  };
}
