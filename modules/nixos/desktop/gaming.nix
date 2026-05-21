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
    heroic
    mangohud
    goverlay
    osu-lazer-bin
    wowup-cf
    vkbasalt
  ];
in {
  config = lib.mkIf cfg.enable {
    systemd.settings.Manager = lib.mkIf cfg.gaming.enable {DefaultLimitNOFILE = 1048576;};

    programs = {
      cdemu.enable = cfg.virtual.enable;
      gamemode.enable = cfg.gaming.enable;

      # AMD GPU tuner: fan curves, power profiles, per-app profiles.
      corectrl.enable = cfg.gaming.enable;

      gamescope = {
        inherit (cfg.gaming) enable;
        capSysNice = true;
        args = [
          "-W 2560"
          "-H 1440"
          "-r 120"
          "--expose-wayland"
        ];
      };

      steam = {
        enable = cfg.gaming.enable && !isContainer;
        #extest.enable = true; # Steam Controller
        localNetworkGameTransfers.openFirewall = true;
        dedicatedServer.openFirewall = true;
        remotePlay.openFirewall = true;
        gamescopeSession.enable = true;
        extraCompatPackages = with pkgs; [proton-ge-bin];
      };
    };

    environment.systemPackages =
      (lib.optionals cfg.gaming.enable gamingPackages)
      ++ (lib.optionals cfg.virtual.enable [pkgs.quickemu]);
  };
}
