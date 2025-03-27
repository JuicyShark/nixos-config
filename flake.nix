{
  /*
    nixpkgs.config = {
    allowUnfree = true;
  };
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      # optionally choose not to download darwin deps (saves some resources on Linux)
      inputs.darwin.follows = "";
    };

    #nixtheplanet.url = "github:matthewcroughan/nixtheplanet";
    stylix = {
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
      url = "github:danth/stylix";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-qml-support = {
      url = "git+https://git.outfoxxed.me/outfoxxed/nix-qml-support";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #retro-ports.url = "github:nadiaholmquist/pc-ports.nix";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (nixpkgs.lib) nixosSystem genAttrs replaceStrings;
    inherit (nixpkgs.lib.filesystem) packagesFromDirectoryRecursive listFilesRecursive;

    forAllSystems = function:
      genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system: function nixpkgs.legacyPackages.${system});

    nameOf = path: replaceStrings [".nix"] [""] (baseNameOf (toString path));
  in {
    packages = forAllSystems (
      pkgs:
        packagesFromDirectoryRecursive {
          inherit (pkgs) callPackage;

          directory = ./packages;
        }
    );

    devShell = forAllSystems (
      pkgs:
        pkgs.mkShell {
          packages = [pkgs.qt6.qtdeclarative];
          shellHook = ''
            onefetch
          '';
        }
    );
    nixosModules = genAttrs (map nameOf (listFilesRecursive ./modules)) (
      name: import ./modules/${name}.nix
    );

    homeModules = genAttrs (map nameOf (listFilesRecursive ./home)) (name: import ./home/${name}.nix);

    /*
      overlays = genAttrs (map nameOf (listFilesRecursive ./overlays)) (
      name: import ./overlays/${name}.nix
    );
    */

    checks = forAllSystems (
      pkgs:
        genAttrs (map nameOf (listFilesRecursive ./tests)) (
          name:
            import ./tests/${name}.nix {
              inherit self pkgs;
            }
        )
    );

    nixosConfigurations = {
      leo = nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        specialArgs.nix-config = self;
        modules = listFilesRecursive ./hosts/leo;
      };
      # Extra Hosts here
    };

    formatter = forAllSystems (pkgs: pkgs.alejandra);
  };
}
