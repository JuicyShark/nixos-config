{
  programs.eza = {
    enable = true;
    enableZshIntegration = false;
    enableBashIntegration = false;
    icons = "auto";

    extraOptions = [
      "--group-directories-first"
      "--no-quotes"
      "--git-ignore"
    ];
  };
}
