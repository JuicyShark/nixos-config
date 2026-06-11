{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  inherit (lib) getExe;
  inherit (pkgs) stdenv;
  flake = osConfig.environment.variables.FLAKE or ".";

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
    groot = "cd \"$(git rev-parse --show-toplevel)\"";

    tls = "tmux list-sessions";

    l = "eza -lF --time-style=long-iso --icons";
    ll = "eza -h --git --icons --color=auto --group-directories-first -s extension";
    tree = "eza --tree --icons --tree";
    nocorrect = "unsetopt correct";
    correct = "setopt correct";

    sf = "fzf-edit";
    sg = "rg-edit";
  };

  linuxAliases = {
    vpn = "mullvad";
    listgen = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";
    bloat = "nix path-info -Sh /run/current-system";
    trimall = "sudo fstrim -va";
    os-build = "nix run ${flake}#os-build --";
    os-switch = "nix run ${flake}#os-switch --";
    os-diff = "nix run ${flake}#os-diff --";
    leo-diff = "nix run ${flake}#os-diff -- leo";
    fallarbor-diff = "nix run ${flake}#os-diff -- fallarbor";
    zues-diff = "nix run ${flake}#zues-diff --";
    test-build = "nix run ${flake}#os-build --";
    switch-build = "nix run ${flake}#os-switch --";
    zues-test = "nix run ${flake}#zues-test --";
    zues-build = "nix run ${flake}#zues-switch --";
  };

  shellAliases = baseAliases // lib.optionalAttrs stdenv.isLinux linuxAliases;
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
      autocd = true;
      history = {
        size = 100000;
        save = 100000;
        ignoreDups = true;
        ignoreAllDups = true;
        ignoreSpace = true;
        share = true;
        expireDuplicatesFirst = true;
      };
      inherit shellAliases;
      initContent = ''
        bindkey -v
        setopt no_beep
        setopt interactive_comments
        setopt complete_in_word
        setopt auto_menu
        setopt auto_cd
        setopt auto_pushd
        setopt pushd_ignore_dups
        setopt pushd_silent
        setopt inc_append_history
        setopt extended_history
        setopt hist_ignore_space
        setopt hist_ignore_dups
        setopt hist_ignore_all_dups
        setopt hist_reduce_blanks
        setopt hist_verify
        setopt hist_expire_dups_first

        if [[ -t 1 ]]; then
          export GPG_TTY="$(tty)"
          if command -v gpg-connect-agent >/dev/null 2>&1; then
            gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
          fi
        fi

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
        bindkey -M viins '^A' beginning-of-line
        bindkey -M viins '^E' end-of-line
        bindkey -M viins '^W' backward-kill-word
        bindkey -M viins '^U' backward-kill-line
        bindkey -M viins '^K' kill-line

        zstyle ':completion:*' menu select
        zstyle ':completion:*' group-name
        zstyle ':completion:*' verbose yes
        zstyle ':completion:*' list-dirs-first true
        zstyle ':completion:*' squeeze-slashes true
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' matcher-list \
          'm:{a-zA-Z}={A-Za-z}' \
          'r:|[._-]=* r:|=*' \
          'l:|=* r:|=*'
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path ~/.cache/zsh
        zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'
        zstyle ':completion:*:messages' format '%F{magenta}%d%f'
        zstyle ':completion:*:warnings' format '%F{red}%d%f'

        fzf-edit() {
          local file
          file="$(rg --files --hidden --glob '!.git/' | fzf --preview 'bat --style=numbers --color=always --line-range=:200 {}')" || return
          [[ -n "$file" ]] && ''${EDITOR:-nvim} "$file"
        }

        rg-edit() {
          local selected file line
          selected="$(rg --line-number --column --no-heading --smart-case "''${*:-.}" | fzf --delimiter : --nth 1,2,3 --preview 'bat --style=numbers --color=always --highlight-line {2} --line-range {2}: {1}')" || return
          [[ -n "$selected" ]] || return
          file="''${selected%%:*}"
          line="''${selected#*:}"
          line="''${line%%:*}"
          ''${EDITOR:-nvim} +"$line" "$file"
        }

        sd() {
          local dir
          dir="$(fd --type d --hidden --exclude .git . | fzf --preview 'eza -la --git --icons --color=always {}')" || return
          [[ -n "$dir" ]] && cd "$dir"
        }

        sp() {
          local dir
          dir="$(fd --hidden --no-ignore --type d --name .git "$HOME/projects" 2>/dev/null | sed 's:/.git$::' | fzf --preview 'eza -la --git --icons --color=always {}')" || return
          [[ -n "$dir" ]] && cd "$dir"
        }

        mkcd() {
          mkdir -p "$1" && cd "$1"
        }

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
      inherit shellAliases;
      bashrcExtra = ''
        if [[ $- == *i* ]]; then
          bind 'set completion-ignore-case on'
          bind 'set show-all-if-ambiguous on'
        fi
      '';
    };
  };
}
