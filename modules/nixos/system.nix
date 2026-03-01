# System Configuration
#
# Core system configuration module that coordinates base modules
# and provides the role-based configuration system.
#
# This module has been refactored to split responsibilities into
# focused base modules for better maintainability.

{
  nix-config,
  system,
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.types) listOf nullOr str;
  inherit (nix-config.inputs.home-manager.nixosModules) home-manager;
  inherit (nix-config.inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}) agenix;
  inherit (lib)
    mkOption
    mkIf
    optional
    optionals
    ;
  inherit (cfg) username;

  cfg = config.modules.system;
  inherit (nix-config.lib.${system}.roles) mkHasRole;
  hasRole = mkHasRole config;
  mkStrOption =
    default:
    mkOption {
      type = str;
      inherit default;
    };
in
{
  imports = [
    home-manager
    nix-config.inputs.agenix.nixosModules.default
    # Base system modules
    ./base/boot.nix
    ./base/nix.nix
    ./base/users.nix
    ./base/locale.nix
    ./base/security.nix
  ];

  options.modules.system = {
    roles = mkOption {
      type = listOf str;
      default = [ ];
      description = "Global role/tag selectors used to enable opinionated defaults.";
    };
    username = mkStrOption "juicy";
    hashedPasswordFile = mkOption {
      type = nullOr str;
      default = null;
    };
    hostName = mkStrOption "nixos";
  };

  config = {
    age = {
      identityPaths = [
        "${config.users.users.${username}.home}/.ssh/id_rsa"
        "${config.users.users.${username}.home}/.ssh/id_ed25519"
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      secrets = {
        wifi-pass.file = ../../secrets/wifi-pass.age;
        juicy-password.file = ../../secrets/juicy-password.age;
      };
    };

    environment = {
      defaultPackages = lib.mkForce [ ];
      systemPackages =
        with pkgs;
        optionals (hasRole "keyboard-zsa") [
          keymapp
          kontroll
        ]
        ++ [ agenix ]
        ++ optional (hasRole "peon-ping") nix-config.packages.${pkgs.stdenv.hostPlatform.system}.peon-ping;
      variables = {
        EDITOR = "nvim";
        VISUAL = if hasRole "desktop-emacs" then "emacs" else "nvim";
      };
    };

    networking = {
      inherit (cfg) hostName;
      useDHCP = lib.mkDefault true;
      enableIPv6 = lib.mkDefault true;
      domain = "local";

      networkmanager = mkIf (hasRole "desktop") {
        enable = true;
        wifi.macAddress = "random";
        unmanaged = [ "interface-name:ve-*" ];
      };

      firewall = {
        allowedUDPPorts = [
          67
          68
          60344
          24800
        ]
        ++ optionals (hasRole "allow-srb2-port") [ 5029 ];
        allowedTCPPorts = [ ] ++ optionals (hasRole "allow-dev-port") [ 3000 ];
      };
    };

    services = {
      resolved.settings.Resolve.LLMNR = "false";

      mullvad-vpn = mkIf (hasRole "mullvad") {
        enable = true;
        enableExcludeWrapper = false;
      };
    };
  };
}
