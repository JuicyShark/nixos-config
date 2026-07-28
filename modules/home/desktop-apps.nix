{
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = osConfig.modules.desktop;
in
  lib.mkIf (pkgs.stdenv.isLinux && (cfg.enable or false)) {
    home.packages =
      lib.optionals (cfg.applications.enable or false) [
        # pkgs.bambu-studio
        pkgs.discord
        pkgs.localsend
        pkgs.obsidian
        pkgs.pwvucontrol
        pkgs.signal-desktop
        pkgs.tidal-hifi
      ]
      ++ lib.optional (cfg.applications.godot.enable or false) pkgs.godot
      ++ lib.optional (cfg.applications.vivaldi.enable or false) pkgs.vivaldi;
  }
