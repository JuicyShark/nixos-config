import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../lock" as Lock

PanelWindow {
	id: root

	default property alias barItems: containment.data;

	anchors {
		left: true
		top: true
		bottom: true
	}

	width: 55
	margins.left: Lock.Controller.locked ? -width : 0
	exclusiveZone: width - margins.left

	color: "transparent"

	WlrLayershell.namespace: "shell:bar"

	readonly property var tooltip: tooltip;
	Tooltip {
		id: tooltip
		bar: root
	}

	readonly property real tooltipXOffset: root.width + 2;

	function boundedY(targetY: real, height: real): real {
		return Math.max(barRect.anchors.topMargin + height, Math.min(barRect.height + barRect.anchors.topMargin - height, targetY))
	}

	Rectangle {
		id: barRect

		anchors {
			fill: parent
			margins: 0
			rightMargin: 0
		}

		color: ShellGlobals.colors.bar
		radius: 0
		border.color: ShellGlobals.colors.barOutline
		border.width: 2

		Item {
			id: containment

			anchors {
				fill: parent
				margins: 0
			}
		}
	}
}
