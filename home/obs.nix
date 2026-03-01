{
  pkgs,
  osConfig,
  lib,
  ...
}:
lib.mkIf (builtins.elem "desktop-streaming" osConfig.modules.system.roles) {
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
