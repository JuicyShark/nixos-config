{
  stdenv,
  fetchFromGitHub,
  pkgs,
}:
stdenv.mkDerivation {
  name = "vim-hy3-nav";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "JuicyShark";
    repo = "vim-hy3-nav";
    rev = "259fa08ae270d89dbe2fc5c113c2602fea3d82d8";
    sha256 = "C9QG8fEFAwnT+av6gxgsEck0rSKrmiainqqt7jKAls0=";
  };

  installPhase = ''
    mkdir -p $out/bin
    install -D vim-hy3-nav $out/bin/vim-hy3-nav
  '';
  buildInputs = [pkgs.jq];

  meta = {
    description = "A Neovim plugin with some handy navigation tools for Hyprland";
    homepage = "https://github.com/JuicyShark/vim-hy3-nav";
  };
}
