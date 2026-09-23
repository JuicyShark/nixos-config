{
  inputs,
  self,
  system,
  homelabFeatures,
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) optionalAttrs;
  cfg = config.modules.profile;
  inherit (cfg) username;
  mediaEnabled = config.modules.system.media.enable;
  # boot.isContainer only exists on NixOS; safe via lazy &&
  isContainer = pkgs.stdenv.hostPlatform.isLinux && config.boot.isContainer;
  hasStylix = config ? stylix && (config.stylix.enable or false);
  defaultHomeDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/${username}"
    else "/home/${username}";
in {
  config = {
    users =
      optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        mutableUsers = false;
      }
      // optionalAttrs (pkgs.stdenv.hostPlatform.isLinux && isContainer) {
        allowNoPasswordLogin = true;
      }
      // optionalAttrs (pkgs.stdenv.hostPlatform.isLinux && mediaEnabled) {
        groups.media.gid = 2000;
      }
      // {
        users =
          optionalAttrs (pkgs.stdenv.hostPlatform.isLinux && mediaEnabled) {
            media = {
              isSystemUser = true;
              uid = 2000;
              group = "media";
              home = "/var/empty";
            };
          }
          // {
            ${username} =
              # NixOS-specific user attributes
              (
                optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
                  isNormalUser = true;
                  openssh.authorizedKeys.keys = [
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILUlQ0gc5NIpsO3qPU7NR9NF8DobGXlhlmVzP944USPC juicy@leo"
                  ];
                  createHome = true;
                  uid = 1000;
                  hashedPasswordFile = config.age.secrets.login-password-hash.path;
                  extraGroups =
                    if isContainer
                    then []
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
                        "uinput"
                        "systemd-journal"
                      ]
                      ++ lib.optional mediaEnabled "media";
                }
              )
              # Darwin: set home dir (shell is set in darwin/system.nix)
              // optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
                home = defaultHomeDirectory;
              };
          };
      };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;

      extraSpecialArgs = {
        inherit inputs self system homelabFeatures;
      };

      sharedModules = [
        {
          home = {
            pointerCursor.enable = lib.mkDefault (pkgs.stdenv.hostPlatform.isLinux && hasStylix);
            stateVersion = cfg.homeStateVersion;
          };
          # generateCaches is slow/broken on darwin
          programs.man.generateCaches = !pkgs.stdenv.hostPlatform.isDarwin;
        }
      ];

      users.${username} = {
        home = {
          inherit username;
          homeDirectory = defaultHomeDirectory;
        };
      };
    };
  };
}
