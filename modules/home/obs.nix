{
  pkgs,
  osConfig,
  lib,
  ...
}:
lib.mkIf (pkgs.stdenv.isLinux && (osConfig.modules.desktop.streaming.enable or false)) {
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
