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
