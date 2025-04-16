import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls


Singleton {
  id: root

  PersistentProperties {
    id: persist
    property bool submapOpen: false;
    property string currentSubmap: ""
  }

  // Listen to Hyprland events and check for submap events
  HyprlandEvent {
    id: hyprEventListener

    // Whenever the event's name or data changes, handle it here
    property string name: ""
    property string data: ""

    // Use a timer to trigger updates based on event changes
    Timer {
      id: updateTimer
      interval: 100
      running: true
      repeat: true
      onTriggered: {
        // Check if the event name matches "submap"
        if (hyprEventListener.name === "submap") {
          const submapName = hyprEventListener.data.trim();

          // If the submap is reset or empty, close the submap
          if (submapName === "reset" || submapName === "") {
            persist.submapOpen = false;
            persist.currentSubmap = "";
          } else {
            persist.submapOpen = true;
            persist.currentSubmap = submapName;
          }
          console.log("Submap updated:", persist.currentSubmap);
        }
      }
    }
  }

  // Lazy loading the submap overlay based on submap state
  LazyLoader {
    id: loader
    activeAsync: persist.submapOpen // This automatically reflects when a submap is open

    PanelWindow {
      width: 350
      height: 7 + searchContainer.implicitHeight + list.topMargin * 2 + list.delegateHeight * 10
      color: "transparent"
      WlrLayershell.namespace: "shell:submapOverlay"

      // The content of the overlay
      Item {
        id: overlayRoot
        width: 400
        height: 300

        // Display the current submap if available
        Rectangle {
          visible: persist.currentSubmap !== ""
          width: 400
          height: 300
          color: "black"
          border.color: "white"

          Text {
            anchors.centerIn: parent
            text: "Submap: " + persist.currentSubmap
            color: "white"
            font.pixelSize: 24
          }
        }
      }
    }
  }
}
