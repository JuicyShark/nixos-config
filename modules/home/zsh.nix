{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  inherit (lib) getExe;
  inherit (pkgs) stdenv;
  flake = osConfig.environment.variables.FLAKE or ".";

  shellAliases =
    {
      ytmp3 = "${getExe pkgs.yt-dlp} -x --continue --add-metadata --embed-thumbnail --audio-format mp3 --audio-quality 0 --metadata-from-title=\"%(artist)s - %(title)s\" --prefer-ffmpeg -o \"%(title)s.%(ext)s\"";
      fm = "y";
      eza = "eza --icons auto --group-directories-first --no-quotes --git-ignore";

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
      gdiff = "git diff --staged";
      gcld = "git clone --depth 1";
      gco = "git checkout";
      gitgrep = "git ls-files | rg";
      groot = "cd \"$(git rev-parse --show-toplevel)\"";

      tls = "tmux list-sessions";

      l = "eza -lF --time-style=long-iso --icons";
      ll = "eza -h --git --icons --color=auto --group-directories-first -s extension";
      tree = "eza --tree --icons";
    }
    // lib.optionalAttrs stdenv.isLinux {
      listgen = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";
      closure-size = "nix path-info -Sh /run/current-system";
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
  zshOnlyAliases = {
    nocorrect = "unsetopt correct";
    correct = "setopt correct";
  };
in {
  home.sessionVariables = {
    CARAPACE_BRIDGES = "carapace,zsh,bash";
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
      shellAliases = shellAliases // zshOnlyAliases;
      initContent = lib.mkBefore ''
        # Make managed SSH shells immediately distinguishable from local work.
        # OSC palette changes are scoped to the current Ghostty surface; the
        # local prompt resets them after `ssh` returns.
        _juicy_set_remote_tty_palette() {
          local -a palette=(
            211827  e85d75  7ccf9a  f5c878
            9aa8ff  c7a6ff  67d5d2  e9e2f0
            665574  ff7890  98e6ae  f9d999
            b6c2ff  dec0ff  86ebe4  fff7ff
          )
          local index

          printf '\e]10;#f7f1ff\a\e]11;#1a1224\a'
          for index in {1..16}; do
            printf '\e]4;%d;#%s\a' $((index - 1)) "$palette[index]"
          done
        }

        _juicy_reset_tty_palette() {
          printf '\e]104;\a\e]110;\a\e]111;\a'
        }

        _juicy_ssh_tty_palette() {
          [[ $TERM == dumb ]] && return
          if [[ -n ''${SSH_CONNECTION-} ]]; then
            _juicy_set_remote_tty_palette
          else
            _juicy_reset_tty_palette
          fi
        }

        autoload -Uz add-zsh-hook
        add-zsh-hook precmd _juicy_ssh_tty_palette
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
