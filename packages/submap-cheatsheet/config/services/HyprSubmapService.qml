import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../lib/HyprHelpers.js" as HyprHelpers

Scope {
  id: root

  property string activeSubmap: ""
  property int retryCount: 0
  property int maxRetries: 5
  property int eventGeneration: 0
  property int requestGeneration: 0
  property bool reconcilePending: false
  readonly property bool inSubmap: activeSubmap.length > 0

  function sync(name) {
    root.activeSubmap = HyprHelpers.normalizeSubmapName(name)
  }

  function reconcile() {
    if (submapProcess.running) {
      root.reconcilePending = true
      return
    }
    root.requestGeneration = root.eventGeneration
    submapProcess.running = true
  }

  function scheduleRetry() {
    if (root.retryCount >= root.maxRetries || retryTimer.running) return
    retryTimer.interval = Math.min(4000, 250 * Math.pow(2, root.retryCount))
    root.retryCount++
    retryTimer.restart()
  }

  Component.onCompleted: reconcile()

  Timer {
    id: retryTimer
    repeat: false
    onTriggered: root.reconcile()
  }

  Process {
    id: submapProcess
    command: ["hyprctl", "submap"]
    stdout: StdioCollector {
      id: submapStdout
      waitForEnd: true
    }
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        retryTimer.stop()
        root.retryCount = 0
        if (root.requestGeneration === root.eventGeneration) {
          root.sync(submapStdout.text)
        }
      } else {
        root.scheduleRetry()
      }
      if (root.reconcilePending) {
        root.reconcilePending = false
        root.reconcile()
      }
    }
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "submap") {
        retryTimer.stop()
        root.retryCount = 0
        root.eventGeneration++
        root.sync(event.data)
      } else if (event.name === "configreloaded") {
        root.retryCount = 0
        root.reconcile()
      }
    }
  }
}
