{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {

      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
      url = "github:danth/stylix";

    };
    ags.url = "github:aylur/ags";
    sakaya = {
      url = "github:donovanglover/sakaya";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mobile-nixos = {
      url = "github:donovanglover/mobile-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland/10a9fec";
      #inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    { self, nixpkgs, ... } @ inputs:
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

      nixosModules = genAttrs (map nameOf (listFilesRecursive ./modules)) (
        name: import ./modules/${name}.nix
      );

      homeModules = genAttrs (map nameOf (listFilesRecursive ./home)) (name: import ./home/${name}.nix);

      overlays = genAttrs (map nameOf (listFilesRecursive ./overlays)) (
        name: import ./overlays/${name}.nix
      );

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

        mobile-nixos = nixosSystem {
          system = "aarch64-linux";
          specialArgs.nix-config = self;
          modules = listFilesRecursive ./hosts/phone;
        };
      };

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
