{
  inputs,
  config,
  ...
}: let
  inherit (inputs.home-manager.darwinModules) home-manager;
  cfg = config.modules.system;
  inherit (cfg) username;
in {
  imports = [
    home-manager
    inputs.agenix.darwinModules.default
    ../nixos/base/options.nix
    ../nixos/base/nix.nix
    ../nixos/base/users.nix
    ../nixos/base/environment.nix
  ];

  config = {
    age.identityPaths = [
      "${config.users.users.${username}.home}/.ssh/id_rsa"
      "${config.users.users.${username}.home}/.ssh/id_ed25519"
    ];

    time.timeZone = "Australia/Brisbane";

    networking.hostName = cfg.hostName;

    users.users.${username}.shell = "/run/current-system/sw/bin/zsh";

    system = {
      stateVersion = 6;
      primaryUser = username;
      defaults = {
        screensaver = {
          askForPassword = true;
          askForPasswordDelay = 0; # require password immediately on wake
        };
        SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
      };
    };

    # macOS security hardening
    networking.applicationFirewall = {
      enable = true;
      enableStealthMode = true;
      allowSignedApp = true;
      allowSigned = true;
    };

    # Power management — "never" disables auto-sleep
    power.sleep.display = "never";
  };
}
