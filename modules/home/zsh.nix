{
  lib,
  pkgs,
  osConfig,
  config,
  ...
}: let
  inherit (lib) getExe;
  inherit (pkgs) stdenv;
  flake = lib.escapeShellArg (osConfig.environment.variables.FLAKE or ".");

  shellAliases =
    {
      fm = "y";

      cleanup = "sudo nix-collect-garbage --delete-older-than 1d";
      nixremove = "nix-store --gc";
      c = "clear";
      q = "exit";
      temp = "cd /tmp/";

      ssh-leo = "ssh leo";
      ssh-zues = "ssh zues";
      ssh-fallarbor = "ssh fallarbor";

      g = "git";
      gs = "git status --short --branch";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull --ff-only";
      gdiff = "git diff --staged";
      gcld = "git clone --depth 1";
      gco = "git checkout";
      gitgrep = "git ls-files | rg";

      tls = "zellij list-sessions";

      l = "eza -lF --time-style=long-iso --icons";
      ll = "eza --long --all --header --git --group-directories-first";
      tree = "eza --tree --level=2 --group-directories-first";
    }
    // lib.optionalAttrs config.programs.yt-dlp.enable {
      ytmp3 = "${getExe config.programs.yt-dlp.package} -x --continue --add-metadata --embed-thumbnail --audio-format mp3 --audio-quality 0 --metadata-from-title=\"%(artist)s - %(title)s\" --prefer-ffmpeg -o \"%(title)s.%(ext)s\"";
    }
    // lib.optionalAttrs config.programs.lazygit.enable {
      gitui = getExe config.programs.lazygit.package;
    }
    // lib.optionalAttrs stdenv.hostPlatform.isLinux {
      listgen = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";
      closure-size = "nix path-info -Sh /run/current-system";
      trimall = "sudo fstrim -va";
      os-build = "nix run ${flake}#os-build --";
      os-switch = "nix run ${flake}#os-switch --";
      os-diff = "nix run ${flake}#os-diff --";
      leo-diff = "nix run ${flake}#os-diff -- leo";
      fallarbor-diff = "nix run ${flake}#os-diff -- fallarbor";
      zues-diff = "nix run ${flake}#zues-diff --";
      zues-test = "nix run ${flake}#zues-test --";
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
    };

    zsh = {
      enable = true;
      defaultKeymap = "emacs";
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
        # Native completion stays predictable; Carapace supplies command specs.
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
        zstyle ':completion:*' menu select
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*:descriptions' format '%B%d%b'

        groot() {
          local root
          root=$(git rev-parse --show-toplevel) || return
          builtin cd -- "$root"
        }

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
