import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
	WlrLayershell.namespace: "shell:notifications"
	exclusionMode: ExclusionMode.Ignore
	color: "transparent"

	anchors {
		left: true
		top: true
		bottom: true
		right: true
	}

	property Component notifComponent: DaemonNotification {}

	NotificationDisplay {
		id: display

		anchors.fill: parent

		stack.y: 5 + (NotificationManager.showTrayNotifs ? 55 : 0)
		stack.x: 72
	}

	visible: display.stack.children.length != 0

	mask: Region { item: display.stack }

	Component.onCompleted: {
		NotificationManager.overlay = this;
		NotificationManager.notif.connect(display.addNotification);
		NotificationManager.showAll.connect(display.addSet);
		NotificationManager.dismissAll.connect(display.dismissAll);
		NotificationManager.discardAll.connect(display.discardAll);
	}
}
