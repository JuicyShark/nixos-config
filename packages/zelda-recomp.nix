{
  stdenv,
  lib,
  pkgs,
  fetchurl,
}:
stdenv.mkDerivation {
  pname = "zelda64-recomp";
  version = "v1.0.0";

  src = fetchurl {
    url = "https://github.com/Mr-Wiseguy/Zelda64Recomp/releases/download/v1.0.0/Zelda64Recompiled-v1.0.0-Linux.tar.gz";
    hash = "sha256-8T2NElBzW8T64qfJpDZeKLx1I5z/tRzhYNkaGqxtu4c=";
  };

  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    gnutar
  ];

  buildInputs = with pkgs; [
    cairo
    gdk-pixbuf
    gtk3
    pango
    atk
    alsa-lib
    SDL
    SDL2
    fontconfig
    freetype
    glib
    libGL
    libpulseaudio
    libusb1
    libxkbcommon
    mesa
    pipewire
    vulkan-loader
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
    xorg.libxkbfile
    xorg.libxshmfence
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -r assets $out/bin
    install -m755 -D Zelda64Recompiled $out/bin/Zelda64Recompiled
    runHook postInstall
  '';

  meta = with lib; {
    description = "Linux native majora's mask recompiled with modern features";
    homepage = "https://github.com/Mr-Wiseguy/Zelda64Recomp";
    license = licenses.mit;
    maintainers = [maintainers.sweetbbak];
  };
}
