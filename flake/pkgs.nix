{
  inputs,
  nixpkgs,
  nixpkgs-stable,
}: let
  inherit (nixpkgs) lib;

  unfreePackages = [
    "2ship2harkinian"
    "bambu-studio"
    "castlabs-electron"
    "discord"
    "keymapp"
    "minecraft-server"
    "n64recomp"
    "aspell-dict-en-science"
    "obsidian"
    "osu-lazer-bin"
    "shipwright"
    "skyfactory5-server-pack"
    "steam"
    "steam-unwrapped"
    "unrar"
    "vivaldi"
    "wowup-cf"
    "xone-dongle-firmware"
  ];

  nixpkgsConfig = {
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreePackages;
  };

  nixpkgsOverlays = [
    inputs.emacs-overlay.overlays.default
    (_final: prev: {
      sunshine = let
        stablePkgs = import nixpkgs-stable {
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

      skyfactory5-server-pack = prev.fetchzip {
        name = "skyfactory5-server-pack-5.0.8";
        url = "https://edge.forgecdn.net/files/6290/699/SkyFactory_5_Server_5.0.8.zip";
        hash = "sha256-UowGdnLar/jWwMwjXpr+wygbRd6xiVl1n+0es84X7x4=";
        stripRoot = false;
        meta = {
          description = "SkyFactory 5 server pack";
          homepage = "https://www.curseforge.com/minecraft/modpacks/skyfactory-5";
          license = prev.lib.licenses.unfreeRedistributable;
          platforms = prev.lib.platforms.unix;
        };
      };

      lazymc = prev.lazymc.overrideAttrs (old: {
        patches =
          (old.patches or [])
          ++ [
            ../patches/lazymc-probe-until-login-ready.patch
          ];
      });
    })
  ];
in {
  inherit nixpkgsConfig nixpkgsOverlays;

  mkPkgs = system:
    import nixpkgs {
      inherit system;
      config = nixpkgsConfig;
      overlays = nixpkgsOverlays;
    };
}
