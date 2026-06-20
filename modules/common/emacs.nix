# Emacs is my main driver. I'm the author of Doom Emacs
# https://github.com/doomemacs. This module sets it up to meet my particular
# Doomy needs.
{
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
  options.modules.emacs = {
    enable = lib.mkEnableOption "Emacs with Doom Emacs configuration";
    package = lib.mkOption {
      type = lib.types.package;
      default = emacs;
      description = "Emacs package used for the system install and user daemon.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      lib.optionals pkgs.stdenv.isLinux [
        binutils # native-comp needs 'as'
        wl-clipboard-rs # org-download clipboard support on Wayland
      ]
      ++ lib.optional (pkgs.stdenv.isLinux && config.programs.gnupg.agent.enable) pinentry-emacs
      ++ [
        cfg.package

        ## Doom dependencies
        git
        ripgrep
        gnutls # for TLS connectivity
        sqlite
        wordnet
        ledger

        python3

        #vterm
        python3Packages.cmake
        gopls
        gore
        gotests
        gomodifytags
        delve

        #python
        python3Packages.black
        python3Packages.debugpy
        python3Packages.pyflakes
        python3Packages.isort
        python3Packages.nose2
        pipenv
        python3Packages.pytest

        #web
        html-tidy
        stylelint
        js-beautify
        gdtoolkit_4

        ## Optional dependencies
        cargo
        fd
        ffmpegthumbnailer
        imagemagick
        libxml2 # xmllint for XML formatting
        lldb
        maim # org-download screenshot backend
        mediainfo
        multimarkdown
        poppler-utils
        rustc
        zstd
        shellcheck
        shfmt
        rust-analyzer
        unzip

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
