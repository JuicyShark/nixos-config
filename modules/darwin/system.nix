{
  inputs,
  config,
  ...
}: let
  inherit (inputs.home-manager.darwinModules) home-manager;
  username = config.modules.profile.username;
in {
  imports = [
    home-manager
    inputs.agenix.darwinModules.default
    ../common/options.nix
    ../common/nix.nix
    ../common/users.nix
    ../common/environment.nix
  ];

  config = {
    age.identityPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
      "${config.users.users.${username}.home}/.ssh/id_rsa"
      "${config.users.users.${username}.home}/.ssh/id_ed25519"
    ];

    time.timeZone = "Australia/Brisbane";

    users.users.${username}.shell = "/run/current-system/sw/bin/zsh";

    system = {
      stateVersion = 6;
      primaryUser = username;
      defaults = {
        NSGlobalDomain = {
          KeyRepeat = 2;
          InitialKeyRepeat = 15;
        };
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

    # Keep the server available without keeping an attached display awake.
    # Display sleep does not suspend launchd daemons such as Jellyfin or Ollama.
    power.sleep.computer = "never";
    power.sleep.display = 1;
  };
}
