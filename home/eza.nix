{
  programs.eza = {
    enable = true;
    enableNushellIntegration = true;
    icons = "auto";

    extraOptions = [
      "--group-directories-first"
      "--no-quotes"
      "--git-ignore"
    ];
  };
}
