# Keymap import surface. Individual workflow files own their bindings.
_: {
  imports = [
    ./keymaps/buffers.nix
    ./keymaps/code.nix
    ./keymaps/diagnostics.nix
    ./keymaps/files.nix
    ./keymaps/git.nix
    ./keymaps/help.nix
    ./keymaps/inspect.nix
    ./keymaps/navigation.nix
    ./keymaps/notes.nix
    ./keymaps/run.nix
    ./keymaps/rust.nix
    ./keymaps/toggles.nix
  ];
}
