# Nix Configuration
#
# Manages Nix package manager settings, garbage collection,
# binary caches, and experimental features.
{
  pkgs,
  config,
  ...
}: let
  username = config.modules.profile.username;
in {
  config = {
    nix = {
      # Follow the NixOS-supported release instead of independently tracking
      # the newest Nix CLI on every host.
      package = pkgs.nixVersions.stable;
      gc.automatic = true;
      optimise.automatic = true;

      settings = {
        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org"
          "https://hyprland.cachix.org"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];

        experimental-features = [
          "nix-command"
          "flakes"
        ];

        trusted-users =
          [username]
          ++ (
            if pkgs.stdenv.hostPlatform.isDarwin
            then ["@admin"]
            else ["@wheel"]
          );
      };
    };
  };
}
