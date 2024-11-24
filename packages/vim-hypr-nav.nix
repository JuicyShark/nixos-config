{
  stdenv,
  fetchFromGitHub,
  installShellFiles,
}:
stdenv.mkDerivation {
  name = "vim-hypr-nav";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "nuchs";
    repo = "vim-hypr-nav";
    rev = "6ab4865a7eb5aad35305298815a4563c9d48556a";
    sha256 = "12gw5mnd1ajr95fmqw48m6s2naz9q9xda75maacm8kz9f47vv1jp";
  };

  nativeBuildInputs = [installShellFiles];

  installPhase = ''
    mkdir -p $out/bin
    cp -r . $out/
    install -D vim-hypr-nav $out/bin/vim-hypr-nav
  '';

  meta = {
    description = "A Neovim plugin with some handy navigational for hyprland tools";
    homepage = "https://github.com/nuchs/vim-hypr-nav";
  };
}
