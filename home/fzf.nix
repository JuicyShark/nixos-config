{lib, ...}: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    colors = lib.mkForce {};

    defaultOptions = ["--height 40%" "--reverse" "--border" "--color=16"];
  };
}
