{
  config,
  lib,
  pkgs,
  ...
}: let
  fileSearchCommand =
    "${lib.getExe pkgs.ripgrep} --files --hidden "
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

    # Use normal text contrast for results; retain Stylix's other roles.
    colors = lib.mkIf (config.lib ? stylix) {
      fg = lib.mkForce config.lib.stylix.colors.withHashtag.base05;
    };
    historyWidget.zsh.command = "";
    historyWidget.bash.command = "";

    defaultOptions = [
      "--height 40%"
      "--reverse"
      "--border"
    ];
    defaultCommand = fileSearchCommand;
    fileWidget = {
      command = fileSearchCommand;
      options = [
        "--preview '${lib.getExe pkgs.bat} --color=always --style=numbers --line-range=:200 -- {}'"
        "--preview-window=right:50%:hidden"
        "--bind=ctrl-/:toggle-preview"
      ];
    };
    changeDirWidget.command = "${lib.getExe pkgs.fd} --type d --hidden --exclude .git --exclude .cache --exclude .direnv --exclude node_modules --exclude .venv";
  };
}
