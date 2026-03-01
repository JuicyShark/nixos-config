{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  bash,
  coreutils,
  curl,
  gnugrep,
  gnused,
  python3,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "peon-ping";
  version = "2.8.1";

  src = fetchFromGitHub {
    owner = "PeonPing";
    repo = "peon-ping";
    rev = "v${finalAttrs.version}";
    hash = "sha256-eTXYNMUxEweBtm1NDM4iSWwzqMM2dJfDJSFDp1FoDpM=";
  };

  passthru.defaultPackSrc = fetchFromGitHub {
    owner = "PeonPing";
    repo = "og-packs";
    rev = "v1.1.0";
    hash = "sha256-spao/GTIhH4c5HOmVc0umMvrwOaMRa4s5Pem1AWyUOw=";
  };

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
                    runHook preInstall

                    install -Dm755 peon.sh $out/share/peon-ping/peon.sh
                    install -Dm755 relay.sh $out/share/peon-ping/relay.sh
                    install -Dm755 install.sh $out/share/peon-ping/install.sh
                    install -Dm755 uninstall.sh $out/share/peon-ping/uninstall.sh
                    install -Dm644 config.json $out/share/peon-ping/config.json
                    install -Dm644 VERSION $out/share/peon-ping/VERSION
                    install -Dm644 completions.bash $out/share/peon-ping/completions.bash
                    install -Dm644 completions.fish $out/share/peon-ping/completions.fish

                    mkdir -p $out/share/peon-ping/adapters
                    cp adapters/*.sh $out/share/peon-ping/adapters/
                    mkdir -p $out/share/peon-ping/adapters/opencode
                    cp adapters/opencode/peon-ping.ts $out/share/peon-ping/adapters/opencode/

                    mkdir -p $out/share/peon-ping/skills
                    cp -r skills/peon-ping-toggle $out/share/peon-ping/skills/
                    cp -r skills/peon-ping-config $out/share/peon-ping/skills/

                    mkdir -p $out/share/openpeon/packs
                    cp -r ${finalAttrs.passthru.defaultPackSrc}/peon $out/share/openpeon/packs/

                    if [ -f docs/peon-icon.png ]; then
                      install -Dm644 docs/peon-icon.png $out/share/peon-ping/docs/peon-icon.png
                    fi

                    makeWrapper ${bash}/bin/bash $out/bin/peon \
                      --add-flags $out/share/peon-ping/peon.sh \
                      --prefix PATH : ${
      lib.makeBinPath [
        coreutils
        curl
        gnugrep
        gnused
        python3
      ]
    }

                    makeWrapper ${bash}/bin/bash $out/bin/peon-ping-setup \
                      --add-flags $out/share/peon-ping/install.sh \
                      --prefix PATH : ${
      lib.makeBinPath [
        coreutils
        curl
        gnugrep
        gnused
        python3
      ]
    }

    install -Dm755 ${./peon-opencode-setup.sh} $out/bin/peon-opencode-setup
    install -Dm755 ${./peon-aider-notify.sh} $out/bin/peon-aider-notify
    install -Dm755 ${./peon-aider-setup.sh} $out/bin/peon-aider-setup
    install -Dm755 ${./peon-profile.sh} $out/bin/peon-profile

    substituteInPlace $out/bin/peon-opencode-setup \
      --replace-fail "@COREUTILS@" "${coreutils}" \
      --replace-fail "@OUT@" "$out" \
      --replace-fail "#!/usr/bin/env bash" "#!${bash}/bin/bash"
    substituteInPlace $out/bin/peon-aider-notify \
      --replace-fail "@BASH@" "${bash}" \
      --replace-fail "@OUT@" "$out" \
      --replace-fail "@PYTHON3@" "${python3}" \
      --replace-fail "#!/usr/bin/env bash" "#!${bash}/bin/bash"
    substituteInPlace $out/bin/peon-aider-setup \
      --replace-fail "@OUT@" "$out" \
      --replace-fail "@PYTHON3@" "${python3}" \
      --replace-fail "#!/usr/bin/env bash" "#!${bash}/bin/bash"
    substituteInPlace $out/bin/peon-profile \
      --replace-fail "@COREUTILS@" "${coreutils}" \
      --replace-fail "@PYTHON3@" "${python3}" \
      --replace-fail "#!/usr/bin/env bash" "#!${bash}/bin/bash"

                    runHook postInstall
  '';

  meta = {
    description = "Sound effects and desktop notifications for AI coding agents";
    homepage = "https://github.com/PeonPing/peon-ping";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "peon";
  };
})
