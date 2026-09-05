{
  lib,
  pkgs,
}: let
  rev = "a0903f9a503f2261e768aa7c23628921c027a88e";
in
  pkgs.stdenvNoCC.mkDerivation {
    pname = "zide";
    version = "unstable-2025-02-26";

    src = pkgs.fetchFromGitHub {
      owner = "josephschmitt";
      repo = "zide";
      inherit rev;
      hash = "sha256-Ten0Jme1wVDsUhRY/ggPY1fKwYRw0FiQWSQqVij3nHI=";
    };

    patches = [./zide.patch];
    nativeBuildInputs = [pkgs.makeWrapper];
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/share/zide"
      cp -R bin layouts lf yazi "$out/share/zide/"
      patchShebangs "$out/share/zide/bin"

      for command in zide zide-edit zide-pick zide-rename; do
        makeWrapper "$out/share/zide/bin/$command" "$out/bin/$command" \
          --prefix PATH : "$out/bin:${lib.makeBinPath [
        pkgs.bc
        pkgs.coreutils
        pkgs.zellij
      ]}"
      done

      wrapProgram "$out/bin/zide" \
        --set-default ZIDE_ALWAYS_NAME true \
        --set-default ZIDE_DEFAULT_LAYOUT default_lazygit \
        --set-default ZIDE_FILE_PICKER yazi \
        --set-default ZIDE_LAYOUT_DIR "$out/share/zide/layouts" \
        --set-default ZIDE_USE_YAZI_CONFIG false

      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      "$out/bin/zide" --help >/dev/null
      grep -q 'ZIDE_DEFAULT_LAYOUT' "$out/bin/zide"
      grep -q 'ZIDE_USE_YAZI_CONFIG' "$out/bin/zide"
      test -f "$out/share/zide/layouts/default.kdl"
      test -f "$out/share/zide/layouts/default_lazygit.kdl"
    '';

    meta = {
      description = "Zellij layouts and scripts for an IDE-like editor and file-picker workspace";
      homepage = "https://github.com/josephschmitt/zide";
      license = lib.licenses.mit;
      mainProgram = "zide";
      platforms = lib.platforms.unix;
    };
  }
