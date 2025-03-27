pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "systray" as SysTray
import "audio" as Audio
import "mpris" as Mpris
import "power" as Power
import "root:notifications" as Notifs

BarContainment {
	id: root

	property bool isSoleBar: Quickshell.screens.length == 1;

  // Top Column
	ColumnLayout {
		anchors {
			left: parent.left
			right: parent.right
			top: parent.top
		}

		ColumnLayout {
			Layout.fillWidth: true

			Notifs.NotificationWidget {
				Layout.fillWidth: true
				bar: root
      }
	  	Mpris.Players {
		  	bar: root
			  Layout.fillWidth: true
		  }
		}
	}


  // Centered Column
  ColumnLayout {
    anchors {
      //centerIn: parent;
			left: parent.left
			right: parent.right
      bottom: parent.bottom
      top: parent.top
    }
    ColumnLayout {
      Layout.fillWidth: true;

      ColumnLayout {
			  spacing: 0
				  Loader {
					  active: root.isSoleBar
					  Layout.preferredHeight: active ? implicitHeight : 0;
					  Layout.fillWidth: true

					  sourceComponent: Workspaces {
					  	bar: root
					  	wsBaseIndex: 1
					  }
			  	}

				Workspaces {
					bar: root
					Layout.fillWidth: true
					wsBaseIndex: root.screen.name == "DP-1" ? 11 : 1;
					hideWhenEmpty: root.isSoleBar
        }
      }
    }
  }

  // Bottom Column
	ColumnLayout {
		anchors {
			left: parent.left
			right: parent.right
			bottom: parent.bottom
		}

		SysTray.SysTray {
			bar: root
			Layout.fillWidth: true
		}

    Audio.AudioControls {
			bar: root
			Layout.fillWidth: true
		}

		ClockWidget {
			bar: root
			Layout.fillWidth: true
		}

	}
}
