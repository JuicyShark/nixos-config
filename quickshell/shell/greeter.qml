import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd
import "background" as Background
import "lock"

ShellRoot {
	GreeterContext {
		id: context

		onLaunch: {
			lock.locked = false;
			Greetd.launch(["hyprland"]);
		}
	}

	WlSessionLock {
		id: lock
		locked: true

		WlSessionLockSurface {
			id: lockSurface

			Background.BackgroundImage {
				id: backgroundImage
				anchors.fill: parent
				screen: lockSurface.screen
				asynchronous: true
			}

			LockContent {
				anchors.fill: parent
				state: context.state
			}
		}
	}
}
