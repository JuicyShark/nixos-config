pragma ComponentBehavior: Bound;

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import ".."
import "root:."

FullwidthMouseArea {
	id: root
	required property var bar;
	required property int wsBaseIndex;
	property int wsCount: 5;
	property bool hideWhenEmpty: false;

	implicitHeight: column.implicitHeight + 10;

	fillWindowWidth: true
	acceptedButtons: Qt.NoButton

	onWheel: event => {
		event.accepted = true;
		const step = -Math.sign(event.angleDelta.y);
		const targetWs = currentIndex + step;

		if (targetWs >= wsBaseIndex && targetWs < wsBaseIndex + wsCount) {
			Hyprland.dispatch(`workspace ${targetWs}`)
		}
	}

	readonly property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen);
	property int currentIndex: 0;
	property int existsCount: 0;
	visible: !hideWhenEmpty || existsCount > 0;

	// destructor takes care of nulling
	signal workspaceAdded(workspace: HyprlandWorkspace);

	ColumnLayout {
		id: column
		spacing: 0
		anchors {
			fill: parent;

      margins: 0;

		}

		Repeater {
			model: root.wsCount

			FullwidthMouseArea {
				id: wsItem
				onPressed: Hyprland.dispatch(`workspace ${wsIndex}`);

				Layout.fillWidth: true
        implicitHeight: animHeight + 5
        //topMargin: 15



				fillWindowWidth: true

				required property int index;
				property int wsIndex: root.wsBaseIndex + index;
				property HyprlandWorkspace workspace: null;
				property bool exists: workspace != null;
				property bool active: (root.monitor?.activeWorkspace ?? false) && root.monitor.activeWorkspace == workspace;

				onActiveChanged: {
					if (active) root.currentIndex = wsIndex;
				}

				onExistsChanged: {
					root.existsCount += exists ? 1 : -1;
				}

				Connections {
					target: root

					function onWorkspaceAdded(workspace: HyprlandWorkspace) {
						if (workspace.id == wsItem.wsIndex) {
							wsItem.workspace = workspace;
						}
					}
				}

        property real animHeight: active ? 125 : (exists ? 75 : 40)
        Behavior on animHeight { NumberAnimation { duration: 150 } }

				Rectangle {
          anchors.centerIn: parent

					height: animHeight
					width: parent.width / 3
					//scale: 1 + wsItem.animActive * 0.3
					radius: height / 2
					border.color: active ? ShellGlobals.colors.base0E : ShellGlobals.colors.base0D;
					border.width: 1

          // Color logic
          color: exists ? (active ? ShellGlobals.colors.base0D
            : ShellGlobals.colors.widgetOutlineSeparate)
            : ShellGlobals.colors.widgetActive;
				}
			}
		}
	}

	Connections {
		target: Hyprland.workspaces

		function onObjectInsertedPost(workspace) {
			root.workspaceAdded(workspace);
		}
	}

	Component.onCompleted: {
		Hyprland.workspaces.values.forEach(workspace => {
			root.workspaceAdded(workspace)
		});
	}
}
