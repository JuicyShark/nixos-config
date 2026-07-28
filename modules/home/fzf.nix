{lib, ...}: let
  fileSearchCommand =
    "rg --files --hidden "
    + (lib.concatMapStringsSep " "
      (glob: "--glob=" + lib.escapeShellArg "!${glob}") [
        ".git/"
        ".cache"
        ".direnv"
        "node_modules"
        "result"
        ".tox"
        ".venv"
      ]);
in {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;

    colors = lib.mkForce {};
    historyWidget.zsh.command = "";
    historyWidget.bash.command = "";

    defaultOptions = [
      "--height 40%"
      "--reverse"
      "--border"
      "--color=16"
    ];
    defaultCommand = fileSearchCommand;
  };
}
