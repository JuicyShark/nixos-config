# Gaming packages and services: Steam, gamemode, Wine, and gaming-adjacent tools.
{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (config.boot) isContainer;
  cfg = config.modules.desktop;

  gamingPackages = with pkgs; [
    legendary-gl
    mangohud
    prismlauncher
  ];
in {
  config = lib.mkIf (cfg.enable && cfg.gaming.enable) {
    systemd.settings.Manager.DefaultLimitNOFILE = 1048576;

    programs = {
      gamemode.enable = true;

      steam = lib.mkIf (!isContainer) {
        enable = true;
        extest.enable = true;

        localNetworkGameTransfers.openFirewall = true;
        dedicatedServer.openFirewall = true;
        remotePlay.openFirewall = true;
        extraCompatPackages = [pkgs.proton-ge-bin];
      };
    };

    environment.systemPackages = gamingPackages;
  };
}
