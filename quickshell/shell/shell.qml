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
import "submapOverlay" as Submap

ShellRoot {
	Component.onCompleted: [Lock.Controller, Launcher.Controller.init(), Submap.Controller.init()]

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
		Bar.Bar {
			screen: Quickshell.find(s => s.name == "DP-1")
    }

	Variants {
		model: Quickshell.screens

		Scope {
			property var modelData



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



        ColumnLayout {
          spacing: 0
              Layout.leftMargin: 275
              Layout.topMargin: 125

          Rectangle {
            Layout.alignment: Qt.AlignCenter
              Layout.preferredHeight: 150
              Layout.preferredWidth: 750

        color: "transparent"
            Text {
              anchors.centerIn: parent

              text: "Welcome Back ${user}"
              color: "black"
              width: 100
              height: 50

            }

          }
          Rectangle {
              Layout.preferredHeight: 150
              Layout.preferredWidth: 750

        color: "transparent"
              Text {
                anchors.centerIn: parent
                text: "The Weather is Currently ${temp} Outside"

              }
            }
        }
			}
		}
	}
}
