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
    prismlauncher
  ];
  extraGamingPackages = with pkgs; [
    goverlay
    osu-lazer-bin
    wowup-cf
    vkbasalt
  ];
  retroGamingPackages = with pkgs; [
    shipwright #LoZ OoT
    dusklight #LoZ twilight
    _2ship2harkinian # LoZ MM
  ];
in {
  config = lib.mkIf cfg.enable {
    systemd.settings.Manager = lib.mkIf cfg.gaming.enable {DefaultLimitNOFILE = 1048576;};

    programs = {
      cdemu.enable = cfg.virtual.enable;
      gamemode.enable = cfg.gaming.enable;

      steam = {
        enable = cfg.gaming.enable && !isContainer;
        #extest.enable = true; # Steam Controller
        localNetworkGameTransfers.openFirewall = true;
        dedicatedServer.openFirewall = true;
        remotePlay.openFirewall = true;
        extraCompatPackages = with pkgs; [proton-ge-bin];
      };
    };

    environment.systemPackages =
      (lib.optionals cfg.gaming.enable gamingPackages)
      ++ (lib.optionals (cfg.gaming.enable && cfg.gaming.extraTools.enable) extraGamingPackages)
      ++ (lib.optionals (cfg.gaming.enable && cfg.gaming.retro.enable) retroGamingPackages)
      ++ (lib.optionals cfg.virtual.enable [pkgs.quickemu]);
  };
}
