pragma Singleton

import QtQuick
import Quickshell

Singleton {
	readonly property string rtpath: "/run/user/1000/quickshell"

  readonly property var colors: QtObject {

    readonly property color base00: "#1e1e2e";
		readonly property color base01: "#181825";
		readonly property color base02: "#313244";
		readonly property color base03: "#45475a";
		readonly property color base04: "#585b70";
		readonly property color base05: "#cdd6f4";
		readonly property color base06: "#f5e0dc";
		readonly property color base07: "#b4befe";
		readonly property color base08: "#f38ba8";
		readonly property color base09: "#fab387";
		readonly property color base0A: "#f9e2af";
		readonly property color base0B: "#a6e3a1";
		readonly property color base0C: "#94e2d5";
		readonly property color base0D: "#89b4fa";
		readonly property color base0E: "#cba6f7";
		readonly property color base0F: "#f2cdcd";

    readonly property color bar: "#181825";
		readonly property color barOutline: "#89b4fa";
		readonly property color widget: "#181825";
		readonly property color widgetActive: "#313244";
		readonly property color widgetOutline: "#1e1e2e";
		readonly property color widgetOutlineSeparate: "#585b70";
		readonly property color separator: "#585b70";
		readonly property color text: "#cdd6f4";

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
