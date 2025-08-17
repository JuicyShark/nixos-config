{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:

let
  inherit (config.lib.stylix.colors.withHashtag) base00;
in
{
  programs.ghostty = lib.mkIf osConfig.modules.desktop.enable {
    enableZshIntegration = true;
    enable = true;
  };
}
