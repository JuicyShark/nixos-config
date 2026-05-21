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
  inherit (cfg) username;
in {
  imports = [
    home-manager
    inputs.agenix.nixosModules.default
    ./base/options.nix
    ./base/boot.nix
    ./base/nix.nix
    ./base/users.nix
    ./base/locale.nix
    ./base/security.nix
    ./base/environment.nix
    ./network.nix
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
      secrets = {
        wifi-pass.file = ../../secrets/wifi-pass.age;
        juicy-password.file = ../../secrets/juicy-password.age;
      };
    };

    environment = {
      defaultPackages = lib.mkForce [];
      systemPackages = with pkgs;
        optionals cfg.keyboard.zsa [
          keymapp
          kontroll
        ];
    };

    networking = {
      inherit (cfg) hostName;
      useDHCP = lib.mkDefault true;
      enableIPv6 = lib.mkDefault true;
      domain = "local";

      firewall = let
        inherit (config.modules) ports;
      in {
        allowedUDPPorts =
          [
            ports.dhcpClient
            ports.dhcpServer
            ports.kdeConnect
            ports.barrier
          ]
          ++ optionals cfg.openSrb2Port [5029];
        allowedTCPPorts = optionals cfg.openDevPort [3000];
      };
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
