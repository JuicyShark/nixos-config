{lib, ...}: {
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    colors = lib.mkForce {};

    defaultOptions = ["--height 40%" "--reverse" "--border" "--color=16"];
  };
}
