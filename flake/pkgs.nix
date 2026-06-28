{
  inputs,
  lib,
  ...
}: let
  unfreePackages = [
    "2ship2harkinian"
    "bloodhound"
    "burpsuite"
    "castlabs-electron"
    "claude"
    "discord"
    "hashcat"
    "keymapp"
    "metasploit"
    "minecraft-server"
    "n64recomp"
    "aspell-dict-en-science"
    "obsidian"
    "osu-lazer-bin"
    "shipwright"
    "steam"
    "steam-unwrapped"
    "vivaldi"
    "wowup-cf"
    "xone-dongle-firmware"
  ];

  nixpkgsOverlays = [
    inputs.emacs-overlay.overlays.default
    inputs.nix-claude-code.overlays.default
    (_final: prev: {
      sunshine = let
        stablePkgs = import inputs.nixpkgs-stable {
          inherit (prev.stdenv.hostPlatform) system;
          config = nixpkgsConfig;
        };
      in
        stablePkgs.sunshine;

      minecraft-server = prev.stdenv.mkDerivation {
        pname = "minecraft-server";
        version = "26.2";

        src = prev.fetchurl {
          url = "https://piston-data.mojang.com/v1/objects/823e2250d24b3ddac457a60c92a6a941943fcd6a/server.jar";
          sha1 = "823e2250d24b3ddac457a60c92a6a941943fcd6a";
        };

        preferLocalBuild = true;
        dontUnpack = true;
        nativeBuildInputs = [prev.makeWrapper];

        installPhase = ''
          runHook preInstall

          install -Dm644 $src $out/lib/minecraft/server.jar

          makeWrapper ${prev.lib.getExe prev.jdk25_headless} $out/bin/minecraft-server \
            --append-flags "-jar $out/lib/minecraft/server.jar nogui" \
            ${prev.lib.optionalString prev.stdenv.hostPlatform.isLinux "--prefix LD_LIBRARY_PATH : ${prev.lib.makeLibraryPath [prev.udev]}"}

          runHook postInstall
        '';

        passthru.updateInfo = {
          manifest = "https://launchermeta.mojang.com/mc/game/version_manifest_v2.json";
          releaseTime = "2026-06-16T12:03:33+00:00";
          serverSha1 = "823e2250d24b3ddac457a60c92a6a941943fcd6a";
        };

        meta = {
          description = "Minecraft Server";
          homepage = "https://minecraft.net";
          sourceProvenance = with prev.lib.sourceTypes; [binaryBytecode];
          license = prev.lib.licenses.unfreeRedistributable;
          platforms = prev.lib.platforms.unix;
          mainProgram = "minecraft-server";
        };
      };

      hyprlandPlugins =
        prev.hyprlandPlugins
        // {
          hyprbars = prev.hyprlandPlugins.hyprbars.overrideAttrs (old: {
            postPatch =
              (old.postPatch or "")
              + ''
                sed -i '/#include <hyprland\/src\/Compositor.hpp>/a #include <hyprland/src/state/MonitorState.hpp>' main.cpp
                substituteInPlace main.cpp \
                  --replace-fail 'g_pCompositor->m_monitors' 'State::monitorState()->monitors()'
              '';
          });
          hy3 = inputs.hy3.packages.${prev.stdenv.hostPlatform.system}.hy3.overrideAttrs (old: {
            postPatch =
              (old.postPatch or "")
              + ''
                substituteInPlace src/Hy3Layout.cpp \
                  --replace-fail '#include <hyprland/src/state/WorkspaceState.hpp>' "" \
                  --replace-fail 'State::workspaceState()->query().id(target.id).run()' 'g_pCompositor->getWorkspaceByID(target.id)' \
                  --replace-fail 'State::workspaceState()->create(target.id, origin_ws->monitorID(), target.name)' 'g_pCompositor->createNewWorkspace(target.id, origin_ws->monitorID(), target.name)'
                sed -i '/auto next_monitor = State::monitorState()/,+4c\	auto next_monitor = g_pCompositor->getMonitorInDirection(this->monitor().lock(), shiftToMathDirection(direction));' src/Hy3Layout.cpp
              '';
          });
        };
    })
  ];

  nixpkgsConfig = {
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreePackages;
  };

  mkPkgs = system:
    import inputs.nixpkgs {
      inherit system;
      config = nixpkgsConfig;
      overlays = nixpkgsOverlays;
    };
in {
  _module.args = {
    inherit mkPkgs nixpkgsConfig nixpkgsOverlays unfreePackages;
  };

  perSystem = {system, ...}: {
    _module.args.pkgs = mkPkgs system;
  };
}
