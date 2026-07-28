{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (inputs.home-manager.nixosModules) home-manager;
  inherit (lib) mkIf optionals;
  cfg = config.modules.system;
  username = config.modules.profile.username;
in {
  imports = [
    home-manager
    inputs.agenix.nixosModules.default
    inputs.nix-index-database.nixosModules.default
    ../common/options.nix
    ./base/boot.nix
    ../common/nix.nix
    ../common/users.nix
    ./base/locale.nix
    ./base/security.nix
    ../common/environment.nix
    ./ports.nix
    ./base/networking.nix
  ];

  config = {
    age = {
      identityPaths = [
        "${config.users.users.${username}.home}/.ssh/id_rsa"
        "${config.users.users.${username}.home}/.ssh/id_ed25519"
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      secrets =
        {juicy-password.file = ../../secrets/juicy-password.age;}
        // lib.optionalAttrs config.modules.haPresence.enable {
          ha-mqtt-pass.file = ../../secrets/ha-mqtt-pass.age;
        };
    };

    environment = {
      defaultPackages = lib.mkForce [];
      systemPackages = with pkgs;
        optionals cfg.keyboard.zsa [
          keymapp
        ];
    };

    networking = {
      useDHCP = lib.mkDefault true;
      enableIPv6 = lib.mkDefault true;
    };

    services = {
      resolved.settings.Resolve.LLMNR = "false";

      mullvad-vpn = mkIf cfg.mullvad.enable {
        enable = true;
        enableExcludeWrapper = false;
      };
    };
  };
}
