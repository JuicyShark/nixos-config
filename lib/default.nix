# Shared Library Functions
#
# This module exports all shared library functions for use across
# NixOS and Home Manager modules.
#
# Usage in modules:
#   let
#     inherit (nix-config.lib.roles) mkHasRole;
#     inherit (nix-config.lib.services) mkScrapeConfig;
#   in
#
# Or for packages:
#   smart-focus-action = nix-config.lib.smart-focus-action;

{
  pkgs,
  lib,
  ...
}:
{
  # Role management helpers
  roles = import ./roles.nix { inherit lib; };

  # Service configuration helpers
  services = import ./services.nix { inherit lib; };

  # Hyprland/Tmux integration utilities
  smart-focus-action = import ./smart-focus-action.nix { inherit pkgs; };
  tmux-terminal-action = import ./tmux-terminal-action.nix { inherit pkgs; };
}
