{
  nixosConfig,
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (nixosConfig._module.specialArgs) nix-config;
  inherit (nix-config.inputs) quickshell;
in {
  home.packages = with pkgs; [
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
  /*
    xdg.configFile."quickshell/manifest.conf".text = lib.generators.toKeyValue {} {
    shell = "${maybeLink ./.}/shell";
    greeter = "${maybeLink ./.}/shell/greeter.qml";

    #  shell = "'/home/juicy/nixos-config/quickshell/shell'";
    #  greeter = "'/home/juicy/nixos-config/quickshell/shell/greeter.qml'";
  };
  */
}
