{
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = osConfig.modules.desktop;
in
  lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && (cfg.enable or false)) {
    home.packages = lib.optionals (cfg.applications.enable or false) [
      # pkgs.bambu-studio
      pkgs.discord
      pkgs.localsend
      pkgs.pwvucontrol
      pkgs.signal-desktop
      pkgs.tidal-hifi
    ];
  }
