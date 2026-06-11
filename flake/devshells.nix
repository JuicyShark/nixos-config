_: {
  perSystem = {pkgs, ...}: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        statix.enable = true;
        deadnix.enable = true;
      };
    };

    devShells = {
      default = pkgs.mkShell {
        packages = with pkgs; [
          alejandra
          statix
          deadnix
          nixd
          treefmt
        ];
        shellHook = ''
          if [ -t 1 ]; then
            fastfetch
          fi
        '';
      };
    };
  };
}
