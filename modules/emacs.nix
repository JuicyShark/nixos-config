# Emacs is my main driver. I'm the author of Doom Emacs
# https://github.com/doomemacs. This module sets it up to meet my particular
# Doomy needs.
{ nix-config, lib, config, pkgs, ... }:

let cfg = config.modules.desktop.emacs;
    emacs = with pkgs; (emacsPackagesFor
      emacs-pgtk).emacsWithPackages (epkgs: with epkgs; [
         treesit-grammars.with-all-grammars
         vterm
         mu4e
       ]);
in {

  config = lib.mkIf cfg {
    nixpkgs.overlays = [
      nix-config.inputs.emacs-overlay.overlays.default
    ];

    environment.systemPackages = with pkgs; [


      ## Emacs itself
      binutils            # native-comp needs 'as', provided by this
      emacs               # HEAD + native-comp

      ## Doom dependencies
      git
      ripgrep
      gnutls              # for TLS connectivity
      sqlite
      wordnet

      ## Optional dependencies
      fd                  # faster projectile indexing
      imagemagick         # for image-dired
      (lib.mkIf (config.programs.gnupg.agent.enable)
        pinentry-emacs)   # in-emacs gnupg prompts
      zstd                # for undo-fu-session/undo-tree compression
      shellcheck
      ## Module dependencies
      # :email mu4e
      mu
      isync
      # :checkers spell
      (aspellWithDicts (ds: with ds; [ en en-computers en-science ]))
      # :tools editorconfig
      editorconfig-core-c # per-project style config
      # :tools lookup & :lang org +roam
      sqlite
      # :lang cc
      clang-tools
      # :lang latex & :lang org (latex previews)
      texlive.combined.scheme-medium
      # :lang beancount
    #  beancount
     # fava
      # :lang nix
      age
    ];

    environment.variables.PATH = [ "$XDG_CONFIG_HOME/emacs/bin" ];

    fonts.packages = [
      (pkgs.nerd-fonts.symbols-only)
    ];
  };
}
