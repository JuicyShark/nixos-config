pragma Singleton

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pam
import ".."
import "../background" as Background

Singleton {
	id: root
	function init() {}

	property bool locked: false;
	onLockedChanged: {
		if (locked) {
			lockContextLoader.active = true;
			lock.locked = true;
		} else {
			lockClearTimer.start();
			workspaceUnlockAnimation();
		}
	}

	Timer {
		id: lockClearTimer
		interval: 600
		onTriggered: {
			lock.locked = false;
			lockContextLoader.active = false;
		}
	}

	property var oldWorkspaces: ({});

	function workspaceLockAnimation() {
		const focusedMonitor = Hyprland.focusedMonitor.id;

		Hyprland.monitors.values.forEach(monitor => {
			if (monitor.activeWorkspace) {
				root.oldWorkspaces[monitor.id] = monitor.activeWorkspace.id;
			}

			Hyprland.dispatch(`workspace name:lock_${monitor.name}`);
		});

		Hyprland.dispatch(`focusmonitor ${focusedMonitor}`);
	}

	function workspaceUnlockAnimation() {
		const focusedMonitor = Hyprland.focusedMonitor.id;

		Hyprland.monitors.values.forEach(monitor => {
			const workspace = root.oldWorkspaces[monitor.id];
			if (workspace) Hyprland.dispatch(`workspace ${workspace}`);
		});

		Hyprland.dispatch(`focusmonitor ${focusedMonitor}`);

		root.oldWorkspaces = ({});
	}

	IpcHandler {
		target: "lockscreen"
		function lock(): void { root.locked = true; }
	}

	LazyLoader {
		id: lockContextLoader

		SessionLockContext {
			onUnlocked: root.locked = false;
		}
	}

	WlSessionLock {
		id: lock

		onSecureChanged: {
			if (secure) {
				root.workspaceLockAnimation();
			}
		}

		WlSessionLockSurface {
			id: lockSurface
			color: "transparent"

			// Ensure nothing spawns in the workspace behind the transparent lock
			// by filling in the background after animations complete.
			Rectangle {
				anchors.fill: parent
				color: "gray"
				visible: backgroundImage.visible
			}

			Background.BackgroundImage {
				id: backgroundImage
				anchors.fill: parent
				screen: lockSurface.screen
				visible: !lockAnim.running
				asynchronous: true
			}

			LockContent {
				id: lockContent
				state: lockContextLoader.item.state;

				visible: false
				width: lockSurface.width
				height: lockSurface.height
			}

			NumberAnimation {
				id: lockAnim
				target: lockContent
				property: "y"
				to: 0
				duration: 600
				easing.type: Easing.BezierSpline
				easing.bezierCurve: [0.0, 0.75, 0.15, 1.0, 1.0, 1.0]
			}

			onVisibleChanged: {
				if (visible) {
					lockContent.y = -lockSurface.height
					lockContent.visible = true;
					lockAnim.running = true;
				}
			}

			Connections {
				target: root

				function onLockedChanged() {
					if (!locked) {
						lockAnim.to = -lockSurface.height
						lockAnim.running = true;
					}
				}
			}
		}
	}
}
