{
  inputs,
  self,
  system,
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) optionalAttrs;
  cfg = config.modules.system;
  inherit (cfg) username;
  inherit (cfg) hashedPasswordFile;
  # boot.isContainer only exists on NixOS; safe via lazy &&
  isContainer = pkgs.stdenv.isLinux && config.boot.isContainer;
  homeDirectory =
    if pkgs.stdenv.isDarwin
    then "/Users/${username}"
    else "/home/${username}";
in {
  config = {
    users =
      optionalAttrs pkgs.stdenv.isLinux {
        mutableUsers = true;
      }
      // optionalAttrs (pkgs.stdenv.isLinux && isContainer) {
        allowNoPasswordLogin = true;
      }
      // optionalAttrs pkgs.stdenv.isLinux {
        groups.media.gid = 2000;
      }
      // {
        users.${username} =
          # NixOS-specific user attributes
          (
            optionalAttrs pkgs.stdenv.isLinux {
              isNormalUser = true;
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILUlQ0gc5NIpsO3qPU7NR9NF8DobGXlhlmVzP944USPC juicy@leo"
              ];
              createHome = true;
              uid = 1000;
              extraGroups =
                if isContainer
                then []
                else [
                  "wheel"
                  "networkmanager"
                  "dialout"
                  "feedbackd"
                  "video"
                  "audio"
                  "render"
                  "input"
                  "uinput"
                  "media"
                ];
            }
            // optionalAttrs (pkgs.stdenv.isLinux && hashedPasswordFile != null) {
              inherit hashedPasswordFile;
            }
          )
          # Darwin: set home dir (shell is set in darwin/system.nix)
          // optionalAttrs pkgs.stdenv.isDarwin {
            home = homeDirectory;
          };
      };

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;

      extraSpecialArgs = {
        inherit inputs self system;
      };

      sharedModules =
        cfg.homeModules
        ++ [
          {
            home.stateVersion = "25.11";
            # generateCaches is slow/broken on darwin
            programs.man.generateCaches = !pkgs.stdenv.isDarwin;
          }
        ];

      users.${username} = {
        home = {
          inherit username homeDirectory;
        };
        nixpkgs.config.allowUnfree = true;
      };
    };
  };
}
