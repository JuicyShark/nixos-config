{
  nixosConfig,
  osConfig,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (nixosConfig._module.specialArgs) nix-config;
  inherit (nix-config.inputs) quickshell;

  stylix = config.lib.stylix.colors.withHashtag;
in
{
  home.packages =
    with pkgs;
    lib.mkIf osConfig.modules.desktop.enable [
      qt6.qtimageformats # amog
      qt6.qt5compat # shader fx
      quickshell.packages.${pkgs.system}.default
      grim
      imagemagick # screenshot
      libsForQt5.qt5.qtgraphicaleffects
      glib
    ];
  home.file."${config.xdg.configHome}/quickshell" = {
    source = ./shell;
    recursive = true;
  };
}
