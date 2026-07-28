# NixVim feature modules. Keep this file as the import surface so individual
# editor subsystems can evolve without turning one plugin file into a junk drawer.
_: {
  imports = [
    ./plugins/completion.nix
    ./plugins/debug.nix
    ./plugins/editing.nix
    ./plugins/git.nix
    ./plugins/lsp.nix
    ./plugins/notes.nix
    ./plugins/tasks.nix
    ./plugins/ui.nix
  ];
}
