# Shared Environment Configuration
#
# Common environment setup for both NixOS and nix-darwin:
# agenix CLI, EDITOR/VISUAL defaults, and FLAKE env var.
# Imported by both nixos/system.nix and darwin/system.nix.
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}) agenix;
  cfg = config.modules.system;
in {
  config = {
    environment = {
      systemPackages = [agenix];
      variables = lib.mkMerge [
        {
          EDITOR = "nvim";
          VISUAL = "nvim"; # emacs.nix overrides this to "emacs" when enabled
        }
        # FLAKE var — use variables (works on both NixOS and darwin)
        (lib.mkIf (cfg.flakePath != null) {FLAKE = cfg.flakePath;})
      ];
    };
  };
}
