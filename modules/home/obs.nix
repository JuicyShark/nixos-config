{
  pkgs,
  osConfig,
  lib,
  ...
}:
lib.mkIf (pkgs.stdenv.isLinux && (osConfig.modules.desktop.streaming.enable or false)) {
  home.packages =
    lib.optionals (osConfig.modules.desktop.streaming.mirror.enable or false) [pkgs.wl-mirror]
    ++ lib.optionals (osConfig.modules.desktop.streaming.chat.enable or false) [pkgs.chatterino2];

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-vkcapture
      obs-pipewire-audio-capture
    ];
  };
}
