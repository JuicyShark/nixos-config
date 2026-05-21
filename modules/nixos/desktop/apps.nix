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
    godot
    vivaldi
    localsend
  ];

  streamingPackages = with pkgs; [
    streamlink
    gpu-screen-recorder # low-overhead AMD HW-encoded replay buffer
  ];
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      (lib.optionals cfg.bloat.enable bloatPackages)
      ++ (lib.optionals cfg.streaming.enable streamingPackages)
      ++ (lib.optionals cfg.guiFallback.enable [pkgs.grsync]);
  };
}
