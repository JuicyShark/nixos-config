{
  pkgs,
  osConfig,
  lib,
  ...
}:
lib.mkIf osConfig.modules.desktop.apps.streaming {
  home.packages = with pkgs; [
    wl-mirror
    chatterino2

  ];
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-vkcapture
      obs-pipewire-audio-capture
    ];
  };
}
