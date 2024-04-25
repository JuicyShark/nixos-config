{ lib
, stdenv
, fetchzip
, fetchFromGitHub
, cmake
, curl
, nasm
, game-music-emu
, libpng
, SDL2
, SDL2_mixer
, libvpx
, libyuv
, zlib
, makeWrapper
, makeDesktopItem
, copyDesktopItems
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ringracers";
  version = "2.0";

  src = fetchFromGitHub {
    owner = "KartKrewDev";
    repo = "RingRacers";
    rev = "v${finalAttrs.version}";
    hash = "sha256-fiKZg/WU8PRyR8RggYHSL0rVUBeFuuQdEKyIj/O0aN4=";
  };

  assets = fetchzip {
    name = "${finalAttrs.pname}-${finalAttrs.version}-assets";
    url = "https://github.com/KartKrewDev/RingRacers/releases/download/v${finalAttrs.version}/Dr.Robotnik.s-Ring-Racers-v${finalAttrs.version}-Assets.zip";
    hash = "sha256-qTWDp5jfpBtEcYmzsxeE6XaohjCjSl/x8eXxnIdhCxY=";
    stripRoot = false;
  };

  nativeBuildInputs = [
    cmake
    nasm
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    curl
    game-music-emu
    libpng
    SDL2
    SDL2_mixer
    libvpx
    libyuv
    zlib
  ];

  cmakeFlags = [
    "-DSRB2_ASSET_DIRECTORY=${finalAttrs.assets}"
    "-DGME_INCLUDE_DIR=${game-music-emu}/include"
    "-DSDL2_MIXER_INCLUDE_DIR=${lib.getDev SDL2_mixer}/include/SDL2"
    "-DSDL2_INCLUDE_DIR=${lib.getDev SDL2}/include/SDL2"
  ];

  desktopItems = [
    (makeDesktopItem rec {
      name = "Ring Racers";
      exec = "ringracers";
      icon = "ringracers";
      comment = "Kart racing mod based on SRB2";
      desktopName = name;
      startupWMClass = ".ringracers-wrapped";
      categories = [ "Game" ];
    })
  ];

  installPhase = ''
    runHook preInstall

    install -Dm644 ../srb2.png $out/share/icons/hicolor/256x256/apps/ringracers.png
    install -Dm755 bin/ringracers $out/bin/ringracers

    wrapProgram $out/bin/ringracers \
      --set RINGRACERSWADDIR "${finalAttrs.assets}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Kart racing video game based on Sonic Robo Blast 2 (SRB2), itself based on a modified version of Doom Legacy";
    homepage = "https://kartkrew.org";
    platforms = platforms.linux;
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ donovanglover ];
    mainProgram = "ringracers";
  };
})