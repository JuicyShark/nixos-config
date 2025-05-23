{pkgs, ...}: {
  home.packages = with pkgs; [tig lazygit gh mgitstatus];

  xdg.configFile."tig/config".text = ''
    color cursor black green bold
    color title-focus black blue bold
    color title-blur black blue bold
  '';

  programs.git = {
    enable = true;

    userEmail = "maxwellb9879@gmail.com";
    userName = "JuicyShark";

    attributes = ["*.lockb binary diff=lockb"];

    extraConfig = {
      include.path = "~/.gituser";

      diff.lockb = {
        textconv = "bun";
        binary = true;
      };

      core = {
        editor = "nvim";
        autocrlf = false;
        quotePath = false;
      };

      push.default = "simple";
      pull.rebase = true;
      fetch.prune = true;
      branch.autosetuprebase = "always";
      init.defaultBranch = "master";
      rerere.enabled = true;
      color.ui = true;

      blame = {date = "relative";};

      "color \"diff-highlight\"" = {
        oldNormal = "red bold";
        oldHighlight = "red bold";
        newNormal = "green bold";
        newHighlight = "green bold ul";
      };

      "color \"diff\"" = {
        meta = "yellow";
        frag = "magenta bold";
        commit = "yellow bold";
        old = "red bold";
        new = "green bold";
        whitespace = "red reverse";
      };
    };

    diff-so-fancy.enable = true;
  };
}
