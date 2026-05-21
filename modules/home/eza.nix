{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    icons = "auto";

    extraOptions = [
      "--group-directories-first"
      "--no-quotes"
      "--git-ignore"
    ];
  };
}
