{
  lib,
  osConfig,
  inputs,
  pkgs,
  ...
}: let
  fullDevPackages = with pkgs; [
    prettierd
    go
    gotools
    cppcheck
    gcc
    gnumake
    cmake
    rustfmt
    cargo-nextest
    gdtoolkit_4
    binutils
    mercurial
    vscode-extensions.vadimcn.vscode-lldb
  ];
in {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./options.nix
    ./plugins/completion.nix
    ./plugins/debug.nix
    ./plugins/editing.nix
    ./plugins/git.nix
    ./plugins/lsp.nix
    ./plugins/formatting.nix
    ./plugins/notes.nix
    ./plugins/tasks.nix
    ./plugins/ui.nix
    ./lua.nix
  ];

  programs.nixvim = {
    enable = true;
    nixpkgs.source = pkgs.path;
    defaultEditor = lib.mkIf (!(osConfig.modules.desktop.enable or false)) true;
    vimdiffAlias = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = false;
    withRuby = false;
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
    globals.mapleader = " ";
    # Keep the Mac editor focused on shell/Nix/Lua work. Full language
    # toolchains and native debuggers belong to the Linux workstation.
    extraPackages =
      (with pkgs; [
        shellcheck
        shfmt
        alejandra
        stylua
        statix
        deadnix
        file
        jq
      ])
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux fullDevPackages;
  };
}
