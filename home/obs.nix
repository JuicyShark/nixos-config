{pkgs, ...}: {
  home.packages = with pkgs; [ wl-mirror ];
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [wlrobs obs-vkcapture obs-pipewire-audio-capture];
  };
}
