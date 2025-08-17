{
  stdenv,
  fetchFromGitHub,
  pkgs,
}:
stdenv.mkDerivation {
  name = "vim-hypr-nav";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "nuchs";
    repo = "vim-hypr-nav";
    rev = "6ab4865a7eb5aad35305298815a4563c9d48556a";
    sha256 = "C9QG8fEFAwnT+av6gxgsEck0rSKrmiainqqt7jKAls0=";
  };

  installPhase = ''
    mkdir -p $out/bin
    install -D vim-hypr-nav $out/bin/vim-hypr-nav
  '';
  buildInputs = [ pkgs.jq ];

  meta = {
    description = "A Neovim plugin with some handy navigation tools for Hyprland";
    homepage = "https://github.com/nuchs/vim-hypr-nav";
  };
}
