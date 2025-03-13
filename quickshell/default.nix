{
  nixosConfig,
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (nixosConfig._module.specialArgs) nix-config;
  inherit (nix-config.inputs) quickshell;

  stylix = config.lib.stylix.colors.withHashtag;
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
  home.file."${config.xdg.configHome}/quickshell/ShellGlobals.qml" = {
  #source = ./shell;
  text = ''
    pragma Singleton

    import QtQuick
    import Quickshell

    Singleton {
    	readonly property string rtpath: "/run/user/1000/quickshell"

    	readonly property var colors: QtObject {
    		readonly property color bar: "#1e1e2e";
    		readonly property color barOutline: "#89b4faff";
    		readonly property color widget: "#181825ff";
    		readonly property color widgetActive: "#585b70ff";
    		readonly property color widgetOutline: "#89b4faff";
    		readonly property color widgetOutlineSeparate: "#313244ff";
        readonly property color separator: "#585b70ff";

        readonly property color base00: "#585b70ff";
        readonly property color base01: "#585b70ff";
        readonly property color base02: "#585b70ff";
        readonly property color base03: "#585b70ff";
        readonly property color base04: "#585b70ff";
        readonly property color base05: "#585b70ff";
        readonly property color base06: "#585b70ff";
        readonly property color base07: "#585b70ff";
        readonly property color base08: "#585b70ff";
        readonly property color base09: "#585b70ff";
        readonly property color base0A: "#585b70ff";
        readonly property color base0B: "#585b70ff";
        readonly property color base0C: "#585b70ff";
        readonly property color base0D: "#585b70ff";
        readonly property color base0E: "#585b70ff";
        readonly property color base0F: "${stylix.base0F}ff";
    	}

    	readonly property var popoutXCurve: EasingCurve {
    		curve.type: Easing.OutQuint
    	}

    	readonly property var popoutYCurve: EasingCurve {
    		curve.type: Easing.InQuart
    	}

    	function interpolateColors(x: real, a: color, b: color): color {
    		const xa = 1.0 - x;
    		return Qt.rgba(a.r * xa + b.r * x, a.g * xa + b.g * x, a.b * xa + b.b * x, a.a * xa + b.a * x);
    	}
    }
  '';
  };
  */
}
