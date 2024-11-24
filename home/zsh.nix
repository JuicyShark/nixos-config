{config, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    autosuggestion.enable = true;

    autocd = false;
    defaultKeymap = null;

    dotDir = ".config/zsh";
    history = {
      size = 5000;
      save = 20000;
      share = true;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      path = "${config.xdg.dataHome}/zsh/zsh_history";
    };
  };
}
