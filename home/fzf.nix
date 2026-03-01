{lib, ...}: let
  ignoredFileGlobs = [
    ".git/"
    ".cache"
    ".direnv"
    "node_modules"
    "result"
    ".tox"
    ".venv"
  ];
  fileSearchCommand =
    "rg --files --hidden " + (lib.concatMapStringsSep " " (glob: "--glob=!" + glob) ignoredFileGlobs);
in {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = false;

    colors = lib.mkForce {};

    defaultOptions = [
      "--height 40%"
      "--reverse"
      "--border"
      "--color=16"
    ];
    defaultCommand = fileSearchCommand;
  };
}
