{

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    caelestia-shell.url = "github:caelestia-dots/shell";
    # use input capture branch
    hyprland = {
      url = "github:3l0w/Hyprland?ref=feat/input-capture-impl";
      inputs.hyprland-protocols.follows = "hyprland-protocols";
      inputs.xdph.url = "github:3l0w/xdg-desktop-portal-hyprland?ref=feat/input-capture-impl";
      inputs.xdph.inputs.hyprland-protocols.follows = "hyprland-protocols";
    };
    hyprland-protocols = {
      url = "github:3l0w/Hyprland-protocols?ref=feat/input-capture-impl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:danth/stylix";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #TODO
    #colmena.url = "github:zhaofengli/colmena";
    # Music
    #vermilion.url = "github:vaxerski/vermilion";

  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (nixpkgs.lib) nixosSystem genAttrs replaceStrings;
      inherit (nixpkgs.lib.filesystem) packagesFromDirectoryRecursive listFilesRecursive;

      forAllSystems =
        function:
        genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ] (system: function nixpkgs.legacyPackages.${system});

      nameOf = path: replaceStrings [ ".nix" ] [ "" ] (baseNameOf (toString path));
    in
    {
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
          packages = [ pkgs.qt6.qtdeclarative ];
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
          specialArgs = { inherit inputs; };
          specialArgs.nix-config = self;
          modules = listFilesRecursive ./hosts/leo;
        };

        # Extra Hosts here
        emerald = nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          specialArgs.nix-config = self;
          modules = listFilesRecursive ./hosts/leo;
        };
        # Extra Hosts here
        fallarbor = nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          specialArgs.nix-config = self;
          modules = listFilesRecursive ./hosts/fallarbor;
        };

        zues = nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          specialArgs.nix-config = self;
          modules = listFilesRecursive ./hosts/zues;
        };
      };
      colmena = {
        meta = {
          nixpkgs = import nixpkgs { system = "x86_64-linux"; };
          nodeNixpkgs = nixpkgs;
        };
        hosts = {
          desktop = {
            deployment.targetHost = "leo.lan";
            imports = [ ./hosts/leo/configuration.nix ];
          };
          server = {
            deployment.targetHost = "zues.lan";
            imports = [ ./hosts/zues/configuration.nix ];
          };
        };
      };
      formatter = forAllSystems (pkgs: pkgs.alejandra);
    };
}
