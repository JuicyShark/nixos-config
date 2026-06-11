# Shared Environment Configuration
#
# Common environment setup for both NixOS and nix-darwin:
# agenix CLI and EDITOR/VISUAL defaults.
# Imported by both nixos/system.nix and darwin/system.nix.
{
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}) agenix;
in {
  config = {
    environment = {
      systemPackages = [agenix];
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim"; # emacs.nix overrides this to "emacs" when enabled
      };
    };
  };
}
