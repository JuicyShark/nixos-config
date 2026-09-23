{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (inputs.home-manager.nixosModules) home-manager;
  inherit (lib) optionals;
  profile = config.modules.profile;
  inherit (profile) username;
in {
  imports = [
    home-manager
    inputs.agenix.nixosModules.default
    inputs.nix-index-database.nixosModules.default
    ../common/options.nix
    ./base/boot.nix
    ../common/nix.nix
    ../common/users.nix
    ./base/security.nix
    ../common/environment.nix
    ./base/networking.nix
  ];

  config = {
    time.timeZone = "Australia/Brisbane";

    i18n = {
      defaultLocale = "en_AU.UTF-8";
      supportedLocales = [
        "en_AU.UTF-8/UTF-8"
        "en_US.UTF-8/UTF-8"
      ];
    };

    age = {
      identityPaths = [
        "${config.users.users.${username}.home}/.ssh/id_rsa"
        "${config.users.users.${username}.home}/.ssh/id_ed25519"
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      secrets =
        {
          login-password-hash = {
            file = ../../secrets/login-password-hash.age;
          };
        }
        // lib.optionalAttrs config.modules.haPresence.enable {
          ha-mqtt-pass = {
            file = ../../secrets/ha-mqtt-pass.age;
            owner = username;
          };
        };
    };

    environment = {
      defaultPackages = lib.mkForce [];
      systemPackages = with pkgs;
        optionals config.hardware.keyboard.zsa.enable [
          keymapp
        ];
    };

    services.resolved.settings.Resolve.LLMNR = "false";

    programs.nh = lib.mkIf (profile.flakePath != null) {
      flake = profile.flakePath;
    };
  };
}
