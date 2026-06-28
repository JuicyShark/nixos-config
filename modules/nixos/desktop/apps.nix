# Desktop application packages: bloat apps, GUI fallback tools, and streaming.
{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop;

  bloatPackages = with pkgs; [
    obsidian
    signal-desktop
    pwvucontrol
    discord
    tidal-hifi
    localsend
  ];
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      (lib.optionals cfg.bloat.enable bloatPackages)
      ++ (lib.optionals (cfg.bloat.enable && cfg.bloat.godot.enable) [pkgs.godot])
      ++ (lib.optionals (cfg.bloat.enable && cfg.bloat.vivaldi.enable) [pkgs.vivaldi])
      ++ (lib.optionals (cfg.streaming.enable && cfg.streaming.streamlink.enable) [pkgs.streamlink])
      ++ (lib.optionals (cfg.streaming.enable && cfg.streaming.replay.enable) [pkgs.gpu-screen-recorder])
      ++ (lib.optionals cfg.guiFallback.enable [pkgs.grsync]);
  };
}
