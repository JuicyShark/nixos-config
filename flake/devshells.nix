pkgs: {
  default = pkgs.mkShell {
    packages = with pkgs; [
      alejandra
      statix
      deadnix
      nixd
      lua-language-server
      lua5_4
      lua54Packages.luacheck
      stylua
      shellcheck
      shfmt
      jq
      ripgrep
      fd
    ];
  };
}
