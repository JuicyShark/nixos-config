{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "smart-focus";
  version = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package.version;
  src = lib.cleanSourceWith {
    src = ./.;
    filter = path: type: baseNameOf path != "target" && lib.cleanSourceFilter path type;
  };
  cargoLock.lockFile = ./Cargo.lock;
  doCheck = true;
  preCheck = ''
    export XDG_RUNTIME_DIR="$TMPDIR/runtime"
    mkdir -p "$XDG_RUNTIME_DIR"
  '';
  meta = {
    description = "Acknowledged application pane and Hyprland focus routing";
    mainProgram = "smart-focus";
    platforms = lib.platforms.linux;
  };
}
