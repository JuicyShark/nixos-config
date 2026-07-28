{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixflix = {
      url = "github:kiriwalawren/nixflix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        darwin.follows = "nix-darwin";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-stable,
    nix-darwin,
    ...
  }: let
    inherit (nixpkgs) lib;

    linuxSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    systems =
      linuxSystems
      ++ [
        "aarch64-darwin"
      ];

    forAllSystems = function: lib.genAttrs systems function;
    forLinuxSystems = function: lib.genAttrs linuxSystems function;

    packageExports = import ./flake/pkgs.nix {
      inherit inputs nixpkgs nixpkgs-stable;
    };
    inherit (packageExports) mkPkgs nixpkgsConfig nixpkgsOverlays;

    moduleExports = import ./flake/modules.nix {inherit nixpkgs;};
    inherit (moduleExports) nixosModules darwinModules homeModules;

    homeProfiles = import ./flake/profiles.nix {inherit homeModules;};

    hostOutputs = import ./flake/hosts.nix {
      inherit
        inputs
        self
        lib
        nixpkgs
        nix-darwin
        homeProfiles
        nixpkgsConfig
        nixpkgsOverlays
        ;
    };

    deploymentApps = import ./flake/apps.nix {inherit lib self;};
    mkDevShells = import ./flake/devshells.nix;
    mkLinuxChecks = import ./flake/checks.nix {inherit self mkPkgs;};
  in {
    inherit nixosModules darwinModules homeModules;
    inherit (moduleExports) lib;
    inherit (hostOutputs) nixosConfigurations darwinConfigurations;

    apps = forLinuxSystems (
      system: let
        pkgs = mkPkgs system;
      in
        deploymentApps pkgs
    );

    devShells = forAllSystems (system: mkDevShells (mkPkgs system));

    formatter = forAllSystems (system: (mkPkgs system).alejandra);

    checks = {
      x86_64-linux = mkLinuxChecks "x86_64-linux";
      aarch64-darwin.mac-eval = self.darwinConfigurations.mac.system;
    };
  };
}
