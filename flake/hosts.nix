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
          inputs.nixflix.nixosModules.default
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
