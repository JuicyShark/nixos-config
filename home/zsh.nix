{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  inherit (lib) getExe;

  navBindings = ''
    bindkey -M viins '^[[1;3D' backward-char
    bindkey -M viins '^[[1;3B' down-line-or-beginning-search
    bindkey -M viins '^[[1;3A' up-line-or-beginning-search
    bindkey -M viins '^[[1;3C' forward-char

    bindkey -M vicmd '^[[1;3D' backward-char
    bindkey -M vicmd '^[[1;3B' down-line-or-beginning-search
    bindkey -M vicmd '^[[1;3A' up-line-or-beginning-search
    bindkey -M vicmd '^[[1;3C' forward-char
  '';

  baseAliases = {
    ytmp3 = "${getExe pkgs.yt-dlp} -x --continue --add-metadata --embed-thumbnail --audio-format mp3 --audio-quality 0 --metadata-from-title=\"%(artist)s - %(title)s\" --prefer-ffmpeg -o \"%(title)s.%(ext)s\"";
    cat = "${getExe pkgs.bat} --number --color=always --paging=never --tabs=2 --wrap=never";
    ls = "eza";
    grep = getExe pkgs.ripgrep;
    find = "fd";
    fm = "y";

    cleanup = "sudo nix-collect-garbage --delete-older-than 1d";
    nixremove = "nix-store --gc";
    c = "clear";
    q = "exit";
    temp = "cd /tmp/";
    gitui = "lazygit";

    ssh-leo = "ssh leo";
    ssh-zues = "ssh zues";
    ssh-fallarbor = "ssh fallarbor";

    g = "git";
    add = "git add .";
    commit = "git commit";
    push = "git push";
    pull = "git pull";
    diff = "git diff --staged";
    gcld = "git clone --depth 1";
    gco = "git checkout";
    gitgrep = "git ls-files | rg";

    ta = "tmux new-session -A -s main";
    tls = "tmux list-sessions";

    l = "eza -lF --time-style=long-iso --icons";
    ll = "eza -h --git --icons --color=auto --group-directories-first -s extension";
    tree = "eza --tree --icons --tree";
    nocorrect = "unsetopt correct";
    correct = "setopt correct";

    sf = "fzf --bind 'enter:become(nvim {})'";
    sg = "rg --line-number --column --no-heading --smart-case . | fzf --delimiter : --nth 1,2,3 --bind 'enter:become(nvim +{2} {1})'";
    sd = "cd \"$(fd --type d --hidden --exclude .git . | fzf)\"";
    sp = "cd \"$(fd --hidden --no-ignore --type d --name .git \"$HOME/projects\" 2>/dev/null | sed 's:/.git$::' | fzf)\"";
  };

  linuxAliases = {
    vpn = "mullvad";
    listgen = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";
    bloat = "nix path-info -Sh /run/current-system";
    trimall = "sudo fstrim -va";
    test-build = "sudo nixos-rebuild test --flake .";
    switch-build = "sudo nixos-rebuild switch --flake .";
    zues-test = "sudo nixos-rebuild test --flake .#zues --target-host zues --sudo --ask-sudo-password";
    zues-build = "sudo nixos-rebuild switch --flake .#zues --target-host zues --sudo --ask-sudo-password";
  };

  shellAliases = baseAliases // lib.optionalAttrs pkgs.stdenv.isLinux linuxAliases;
in {
  home.sessionVariables = {
    CARAPACE_BRIDGES = "carapace,zsh,bash";
    NIXPKGS_ALLOW_UNFREE = "1";
    NIXPKGS_ALLOW_INSECURE = "1";
  };

  programs = {
    carapace = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = {
        size = 10000;
        save = 10000;
        ignoreDups = true;
        ignoreAllDups = true;
        ignoreSpace = true;
        share = false;
        expireDuplicatesFirst = true;
      };
      shellAliases = shellAliases;
      initContent = ''
        bindkey -v
        setopt no_beep
        setopt interactive_comments
        setopt correct
        setopt complete_in_word
        setopt auto_menu
        setopt inc_append_history
        setopt hist_reduce_blanks

        autoload -Uz run-help
        alias help=run-help

        autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
        bindkey '^[[A' up-line-or-beginning-search
        bindkey '^[[B' down-line-or-beginning-search
        bindkey '^P' up-line-or-beginning-search
        bindkey '^N' down-line-or-beginning-search

        ${navBindings}

        autoload -Uz edit-command-line
        zle -N edit-command-line
        bindkey -M vicmd 'v' edit-command-line

        zstyle ':completion:*' menu select
        zstyle ':completion:*' group-name
        zstyle ':completion:*' verbose yes
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path ~/.cache/zsh
        zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'
        zstyle ':completion:*:messages' format '%F{magenta}%d%f'
        zstyle ':completion:*:warnings' format '%F{red}%d%f'

        if (( $+widgets[_atuin_search_widget] )); then
          bindkey '^R' _atuin_search_widget
          bindkey -M viins '^R' _atuin_search_widget
          bindkey -M vicmd '^R' _atuin_search_widget
        fi

      '';
    };

    bash = {
      enable = true;
      enableCompletion = true;
      historyControl = [
        "ignoredups"
        "ignorespace"
      ];
      historySize = 10000;
      historyFileSize = 10000;
      shellAliases = shellAliases;
      bashrcExtra = ''
        bind 'set completion-ignore-case on'
        bind 'set show-all-if-ambiguous on'
      '';
    };
  };
}
