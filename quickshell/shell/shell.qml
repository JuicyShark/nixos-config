//@ pragma ShellId shell
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "background" as Background
import "screenshot" as Screenshot
import "bar" as Bar
import "lock" as Lock
import "notifications" as Notifs
import "launcher" as Launcher

ShellRoot {
	Component.onCompleted: [Lock.Controller, Launcher.Controller.init()]

	ReloadPopup {}

	Process {
		command: ["mkdir", "-p", ShellGlobals.rtpath]
		running: true
	}

	LazyLoader {
		id: screenshot
		loading: true

		Screenshot.Controller {
		}
	}

	Connections {
		target: ShellIpc

		function onScreenshot() {
			screenshot.item.shooting = true;
		}
	}

	Notifs.NotificationOverlay {
		screen: Quickshell.screens.find(s => s.name == "DP-1")
	}

	Variants {
		model: Quickshell.screens

		Scope {
			property var modelData

			Bar.Bar {
				screen: modelData
			}

      //Background Overlay
			PanelWindow {
				id: window

				screen: modelData
        color: "transparent"
        visible: true
				exclusionMode: ExclusionMode.Ignore
				WlrLayershell.layer: WlrLayer.Background
				WlrLayershell.namespace: "shell:background"

				anchors {
					top: true
					bottom: true
					left: true
					right: true
        }

        Text {

          text: "Hey"
          color: "black"
        }
			}
		}
	}
}
