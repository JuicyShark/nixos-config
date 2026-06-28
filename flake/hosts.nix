{
  inputs,
  self,
  lib,
  homeProfiles,
  nixpkgsConfig,
  nixpkgsOverlays,
  ...
}: let
  specialArgs = system: {
    inherit inputs self system homeProfiles;
  };

  nixpkgsModule = {
    nixpkgs = {
      config = nixpkgsConfig;
      overlays = nixpkgsOverlays;
    };
  };

  patchedNixflix = system:
    inputs.nixpkgs.legacyPackages.${system}.applyPatches {
      name = "nixflix-patched";
      src = inputs.nixflix;
      patches = [
        ../patches/nixflix-prowlarr-indexer-field-secrets.patch
      ];
    };

  patchedNixflixModule = system: {
    imports = [
      (import "${patchedNixflix system}/modules")
      inputs.nixflix.inputs.vpn-confinement.nixosModules.default
    ];
  };

  mkNixosHost = {
    name,
    system,
    extraModules ? [],
    includeHardware ? true,
  }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = specialArgs system;
      modules =
        [
          nixpkgsModule
          ../hosts/${name}/configuration.nix
        ]
        ++ lib.optional includeHardware ../hosts/${name}/hardware-configuration.nix
        ++ extraModules;
    };

  mkDarwinHost = name: system:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = specialArgs system;
      modules = [
        nixpkgsModule
        ../hosts/${name}/configuration.nix
      ];
    };
in {
  flake = {
    nixosConfigurations = {
      leo = mkNixosHost {
        name = "leo";
        system = "x86_64-linux";
      };
      fallarbor = mkNixosHost {
        name = "fallarbor";
        system = "x86_64-linux";
      };
      zues = mkNixosHost {
        name = "zues";
        system = "x86_64-linux";
        extraModules = [
          (patchedNixflixModule "x86_64-linux")
          ../hosts/zues/networking.nix
          ../hosts/zues/services.nix
          ../hosts/zues/gatus.nix
        ];
      };
      iso = mkNixosHost {
        name = "iso";
        system = "x86_64-linux";
        includeHardware = false;
      };
    };

    darwinConfigurations = {
      mac = mkDarwinHost "mac" "aarch64-darwin";
    };
  };
}
