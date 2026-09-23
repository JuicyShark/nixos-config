{
  lib,
  stdenvNoCC,
  makeWrapper,
  quickshell,
}:
stdenvNoCC.mkDerivation {
  pname = "submap-cheatsheet";
  version = "0.1.0";

  src = ./config;
  nativeBuildInputs = [makeWrapper];
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/submap-cheatsheet"
    cp -r "$src"/. "$out/share/submap-cheatsheet/"

    mkdir -p "$out/bin"
    makeWrapper "${lib.getExe quickshell}" "$out/bin/submap-cheatsheet" \
      --add-flags "--path $out/share/submap-cheatsheet/shell.qml" \
      --prefix XDG_DATA_DIRS : "$out/share"

    mkdir -p "$out/share/applications"
    cat > "$out/share/applications/submap-cheatsheet.desktop" <<'EOF'
    [Desktop Entry]
    Type=Application
    Name=Submap Cheatsheet
    Comment=Hyprland submap overlay powered by Quickshell
    Exec=submap-cheatsheet
    Terminal=false
    Categories=Utility;
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Which-key inspired Hyprland submap overlay for Quickshell";
    mainProgram = "submap-cheatsheet";
    platforms = lib.platforms.linux;
  };
}
