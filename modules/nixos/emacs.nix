# Emacs is my main driver. I'm the author of Doom Emacs
# https://github.com/doomemacs. This module sets it up to meet my particular
# Doomy needs.
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.modules.emacs;
  # emacs-pgtk requires GTK/Wayland (Linux only); emacs-macport is the macOS native port
  emacsBase =
    if pkgs.stdenv.isDarwin
    then pkgs.emacs-macport
    else pkgs.emacs-pgtk;
  emacs = with pkgs;
    (emacsPackagesFor emacsBase).emacsWithPackages (
      epkgs:
        with epkgs; [
          treesit-grammars.with-all-grammars
          vterm
          mu4e
        ]
    );
in {
  options.modules.emacs.enable = lib.mkEnableOption "Emacs with Doom Emacs configuration";

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.emacs-overlay.overlays.default
    ];
    environment.systemPackages = with pkgs;
      lib.optionals pkgs.stdenv.isLinux [
        binutils # native-comp needs 'as'
      ]
      ++ lib.optional (pkgs.stdenv.isLinux && config.programs.gnupg.agent.enable) pinentry-emacs
      ++ [
        emacs

        ## Doom dependencies
        git
        ripgrep
        gnutls # for TLS connectivity
        sqlite
        wordnet
        ledger

        #vterm
        python3Packages.cmake
        gopls
        gore
        gotests
        gomodifytags

        #python
        python3Packages.black
        python3Packages.pyflakes
        python3Packages.isort
        pipenv
        python3Packages.pytest

        #web
        html-tidy
        stylelint
        js-beautify

        ## Optional dependencies
        fd
        imagemagick
        zstd
        shellcheck
        shfmt
        rust-analyzer

        ## Module dependencies
        # :email mu4e
        mu
        isync
        # :checkers spell
        (aspellWithDicts (ds: with ds; [en en-computers en-science]))
        # :tools editorconfig
        editorconfig-core-c
        sqlite
        graphviz

        # :lang cc
        clang-tools
        gnumake

        # :lang nix
        age
        nixfmt
      ];

    fonts.packages = [pkgs.nerd-fonts.symbols-only];

    environment.variables.VISUAL = lib.mkForce "emacs";
  };
}
