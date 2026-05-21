{
  lib,
  osConfig,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./options.nix
    ./plugins.nix
    ./keymaps.nix
    ./lua.nix
  ];

  home.packages = with pkgs; [
    alejandra
    lsof
    glib
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor =
      lib.mkIf (
        !(osConfig.modules.desktop.enable or false) && !(osConfig.modules.emacs.enable or false)
      )
      true;
    vimdiffAlias = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = false;
    withRuby = false;
    dependencies.nodejs.enable = false;
    # Inject the language named in a /* lang */ comment into the string that
    # immediately follows it. Lets `/* lua */ ''...''` highlight as Lua inside
    # .nix files (e.g. modules/home/hyprland/lua.nix).
    extraFiles."after/queries/nix/injections.scm".text = ''
      ;; extends

      ((comment) @injection.language
        .
        [
          (string_expression (string_fragment) @injection.content)
          (indented_string_expression (string_fragment) @injection.content)
        ]
        (#gsub! @injection.language "/%*%s*([%w%p]+)%s*%*/" "%1")
        (#set! injection.combined))
    '';

    globals = {
      mapleader = " ";
      maplocalleader = "<C-Space>";

      loaded_ruby_provider = 0;
      loaded_perl_provider = 0;
      loaded_python_provider = 0;
      loaded_python3_provider = 0;
      loaded_node_provider = 0;
      loaded_npm_provider = 0;
    };
    extraPackages = with pkgs; [
      lua-language-server
      nil
      rust-analyzer
      vscode-langservers-extracted
      bash-language-server
      shellcheck
      shfmt
      tree-sitter

      prettierd
      alejandra
      stylua
      sqlite

      # C / C++ — clangd + clang-format + build tools for compiler.nvim
      clang-tools
      cppcheck
      gcc
      gnumake
      cmake

      # Rust formatter (rustaceanvim drives rust-analyzer; rustfmt binary still needed for conform)
      rustfmt

      # Nix linters matched to the repo's devShell
      statix
      deadnix

      # Binary / low-level exploration used by :Disasm / :Strings / :Hexdump / :NixDrv
      binutils
      file
      jq

      # DAP adapter for c/cpp/rust
      vscode-extensions.vadimcn.vscode-lldb
    ];
  };
}
