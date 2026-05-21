# Nix Configuration
#
# Manages Nix package manager settings, garbage collection,
# binary caches, and experimental features.
{
  config,
  pkgs,
  ...
}: let
  inherit (config.modules.system) username;
in {
  config = {
    nixpkgs.config.allowUnfree = true;

    nix = {
      package = pkgs.nixVersions.latest;
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
          "max-deploy:3kPzEf0z7cR3xHAgh2bsS0lp9GZGWzEKsw/ZuQc1z60="
        ];

        auto-optimise-store = true;
        warn-dirty = true;
        keep-going = true;

        experimental-features = [
          "nix-command"
          "flakes"
        ];

        trusted-users =
          [username]
          ++ (
            if pkgs.stdenv.isDarwin
            then ["@admin"]
            else ["@wheel"]
          );
      };
    };
  };
}
