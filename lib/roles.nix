# Role Helper Functions
#
# Provides utility functions for checking system roles across modules.
# Eliminates the need to define hasRole in every module.
#
# Usage in NixOS modules:
#   let
#     inherit (nix-config.lib.roles) mkHasRole;
#     hasRole = mkHasRole config;
#   in
#
# Usage in Home Manager modules:
#   let
#     inherit (nix-config.lib.roles) mkHasRoleHome;
#     hasRole = mkHasRoleHome osConfig;
#   in

{ lib }:
{
  # For NixOS modules - checks roles in config.modules.system.roles
  mkHasRole = config: role: builtins.elem role config.modules.system.roles;

  # For Home Manager modules - checks roles in osConfig.modules.system.roles
  mkHasRoleHome = osConfig: role: builtins.elem role osConfig.modules.system.roles;

  # Check if ANY of the provided roles is present
  mkHasAnyRole =
    config: roles: builtins.any (role: builtins.elem role config.modules.system.roles) roles;

  # Check if ALL of the provided roles are present
  mkHasAllRoles =
    config: roles: builtins.all (role: builtins.elem role config.modules.system.roles) roles;

  # Get all roles for a configuration
  getRoles = config: config.modules.system.roles;

  # Check if roles list is non-empty
  hasAnyRoles = config: (builtins.length config.modules.system.roles) > 0;
}
