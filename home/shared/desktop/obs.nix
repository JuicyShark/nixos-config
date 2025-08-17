{
  pkgs,
  osConfig,
  lib,
  ...
}:
{
  home.packages = with pkgs; lib.mkIf osConfig.modules.desktop.apps.streaming [ wl-mirror ];
  programs.obs-studio = {
    enable = lib.mkIf osConfig.modules.desktop.apps.streaming true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-vkcapture
      obs-pipewire-audio-capture
    ];
  };
}
