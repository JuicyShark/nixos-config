import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  // Required bar widget properties
  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  // Per-screen bar properties
  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  // State
  property var minimizedWindows: []
  property int windowCount: minimizedWindows.length

  // Hide widget when no minimized windows
  visible: windowCount > 0

  implicitWidth: isBarVertical ? capsuleHeight : layout.implicitWidth + Style.marginM * 2
  implicitHeight: isBarVertical ? layout.implicitHeight + Style.marginM * 2 : capsuleHeight

  Rectangle {
    id: visualCapsule
    anchors.centerIn: parent
    width: root.implicitWidth
    height: root.implicitHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth
    radius: Style.radiusL

    Item {
      id: layout
      anchors.centerIn: parent
      implicitWidth: isBarVertical ? col.implicitWidth : row.implicitWidth
      implicitHeight: isBarVertical ? col.implicitHeight : row.implicitHeight

      RowLayout {
        id: row
        visible: !root.isBarVertical
        anchors.centerIn: parent
        spacing: Style.marginS

        NIcon {
          icon: "window-minimize"
          color: Color.mOnSurface
          Layout.preferredWidth: root.barFontSize
          Layout.preferredHeight: root.barFontSize
        }

        NText {
          text: root.windowCount.toString()
          color: Color.mOnSurface
          font.pixelSize: root.barFontSize
          font.weight: Font.Bold
        }
      }

      ColumnLayout {
        id: col
        visible: root.isBarVertical
        anchors.centerIn: parent
        spacing: Style.marginS

        NIcon {
          icon: "window-minimize"
          color: Color.mOnSurface
          Layout.preferredWidth: root.barFontSize
          Layout.preferredHeight: root.barFontSize
          Layout.alignment: Qt.AlignHCenter
        }

        NText {
          text: root.windowCount.toString()
          color: Color.mOnSurface
          font.pixelSize: root.barFontSize
          font.weight: Font.Bold
          Layout.alignment: Qt.AlignHCenter
        }
      }
    }
  }

  // Context menu built dynamically from minimized window list
  NPopupContextMenu {
    id: contextMenu

    model: {
      let items = [];
      for (let i = 0; i < root.minimizedWindows.length; i++) {
        let w = root.minimizedWindows[i];
        let label = w.title || w.class || "Unknown";
        if (label.length > 50) label = label.substring(0, 47) + "...";
        items.push({
          "label": label,
          "action": w.address,
          "icon": "window-maximize"
        });
      }
      if (items.length > 0) {
        items.push({
          "label": "Restore All",
          "action": "restore-all",
          "icon": "arrows-maximize"
        });
      }
      return items;
    }

    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);

      if (action === "restore-all") {
        restoreAllProcess.running = true;
      } else {
        restoreSingleProcess.command = [
          "hyprctl", "dispatch", "movetoworkspace", "e+0,address:" + action
        ];
        restoreSingleProcess.running = true;
      }
    }
  }

  // Poll hyprctl for clients on special:minimized
  Process {
    id: fetchProcess
    command: ["bash", "-c", "hyprctl clients -j | jq -c '[.[] | select(.workspace.name == \"special:minimized\") | {address, class, title}]'"]
    running: false

    stdout: SplitParser {
      onRead: data => {
        try {
          root.minimizedWindows = JSON.parse(data);
        } catch (e) {
          Logger.e("Minimized", "Failed to parse hyprctl output:", e);
          root.minimizedWindows = [];
        }
      }
    }

    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        root.minimizedWindows = [];
      }
    }
  }

  // Restore a single window to current workspace
  Process {
    id: restoreSingleProcess
    running: false

    onExited: {
      fetchProcess.running = true;
    }
  }

  // Restore all minimized windows
  Process {
    id: restoreAllProcess
    command: ["bash", "-c", "hyprctl clients -j | jq -r '.[] | select(.workspace.name == \"special:minimized\") | .address' | while read addr; do hyprctl dispatch movetoworkspace e+0,address:$addr; done"]
    running: false

    onExited: {
      fetchProcess.running = true;
    }
  }

  Timer {
    id: pollTimer
    interval: pluginApi?.pluginSettings?.pollIntervalMs || 1500
    repeat: true
    running: true
    onTriggered: {
      fetchProcess.running = true;
    }
  }

  Component.onCompleted: {
    fetchProcess.running = true;
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onEntered: {
      let tip = root.windowCount === 1
        ? "1 minimized window"
        : root.windowCount + " minimized windows";
      TooltipService.show(root, tip, BarService.getTooltipDirection(root.screenName));
    }
    onExited: {
      TooltipService.hide();
    }

    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        // Single minimized window: restore immediately
        if (root.windowCount === 1) {
          restoreSingleProcess.command = [
            "hyprctl", "dispatch", "movetoworkspace",
            "e+0,address:" + root.minimizedWindows[0].address
          ];
          restoreSingleProcess.running = true;
        } else {
          PanelService.showContextMenu(contextMenu, root, screen);
        }
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
      }
    }
  }
}
