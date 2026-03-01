# User Management
#
# Manages user accounts and home-manager integration.
# Extracted from system.nix for better modularity.

{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.system;
  username = cfg.username;
  hashedPasswordFile = cfg.hashedPasswordFile;
  isContainer = config.boot.isContainer;
in
{
  config = {
    users = {
      mutableUsers = true;
      allowNoPasswordLogin = mkIf isContainer true;

      users.${username} = {
        isNormalUser = true;
        createHome = true;
        uid = 1000;

        extraGroups =
          if isContainer then
            [ ]
          else
            [
              "wheel"
              "networkmanager"
              "dialout"
              "feedbackd"
              "video"
              "audio"
              "render"
              "input"
              "media"
            ];
      }
      // optionalAttrs (hashedPasswordFile != null) { inherit hashedPasswordFile; };
    };

    # Home-manager integration
    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;

      sharedModules = [
        {
          home.stateVersion = "25.11";
          programs.man.generateCaches = true;
        }
      ];

      users.${username} = {
        home = {
          inherit username;
          homeDirectory = "/home/${username}";
        };
        nixpkgs.config.allowUnfree = true;
      };
    };
  };
}
