{
  pkgs,
  osConfig,
  lib,
  ...
}:
lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && (osConfig.modules.desktop.streaming.enable or false)) {
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-vkcapture
      obs-pipewire-audio-capture
    ];
  };
}
