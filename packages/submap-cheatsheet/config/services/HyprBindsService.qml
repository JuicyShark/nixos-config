import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../lib/BindModel.js" as BindModel

Scope {
  id: root

  property bool loading: false
  property string errorText: ""
  // bindsBySubmap: submap key → grouped bind array
  //   [ { category: string, isExitGroup: bool, binds: NormalizedBind[] } ]
  property var bindsBySubmap: ({})
  property bool usingCache: false
  property string lastPayload: ""
  property bool refreshPending: false
  property int retryCount: 0
  property int maxRetries: 5

  function hasCachedBinds() {
    return Object.keys(root.bindsBySubmap).length > 0
  }

  function markCacheIfAvailable() {
    if (root.hasCachedBinds()) {
      root.usingCache = true
    }
  }

  function bindsForSubmap(submapName) {
    return BindModel.bindsForSubmap(root.bindsBySubmap, submapName)
  }

  // ── data fetching ─────────────────────────────────────────────────────────
  //
  // Source of truth is Hyprland's native bind registry.

  function ingest(payload) {
    if (!payload) {
      return false
    }
    if (payload === root.lastPayload) {
      retryTimer.stop()
      root.errorText = ""
      root.usingCache = false
      root.loading = false
      root.retryCount = 0
      return true
    }
    try {
      const parsed = JSON.parse(payload)
      if (!Array.isArray(parsed)) {
        return false
      }
      root.bindsBySubmap = BindModel.buildIndex(parsed)
      root.lastPayload = payload
      retryTimer.stop()
      root.errorText = ""
      root.usingCache = false
      root.loading = false
      root.retryCount = 0
      return true
    } catch (err) {
      return false
    }
  }

  function scheduleRetry() {
    if (root.retryCount >= root.maxRetries || retryTimer.running) return
    retryTimer.interval = Math.min(4000, 250 * Math.pow(2, root.retryCount))
    root.retryCount++
    retryTimer.restart()
  }

  function fail(message) {
    root.errorText = message
    root.markCacheIfAvailable()
    root.loading = false
    root.scheduleRetry()
  }

  function startFetch() {
    if (bindsProcess.running) {
      root.refreshPending = true
      return
    }
    root.loading = true
    bindsProcess.running = true
  }

  function finishFetch(exitCode) {
    const stderrText = String(bindsStderr.text || "").trim().replace(/\s+/g, " ")
    const payload = String(bindsStdout.text || "")
    const success = exitCode === 0 && root.ingest(payload)

    if (!success) {
      const detail = exitCode !== 0
        ? ("hyprctl binds exited " + String(exitCode))
        : "hyprctl binds returned invalid data"
      root.fail(stderrText.length > 0 ? (detail + ": " + stderrText) : detail)
    }

    if (root.refreshPending) {
      root.refreshPending = false
      retryTimer.stop()
      refreshDebounce.restart()
    }
  }

  function refresh() {
    root.loading = true
    if (bindsProcess.running) {
      root.refreshPending = true
      return
    }
    refreshDebounce.restart()
  }

  Component.onCompleted: refresh()

  Timer {
    id: refreshDebounce
    interval: 30
    repeat: false
    onTriggered: root.startFetch()
  }

  Timer {
    id: retryTimer
    repeat: false
    onTriggered: root.refresh()
  }

  Process {
    id: bindsProcess
    command: ["hyprctl", "-j", "binds"]
    stdout: StdioCollector {
      id: bindsStdout
      waitForEnd: true
    }
    stderr: StdioCollector {
      id: bindsStderr
      waitForEnd: true
    }
    onExited: (exitCode, exitStatus) => root.finishFetch(exitCode)
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "configreloaded") {
        retryTimer.stop()
        root.retryCount = 0
        root.refresh()
      } else if (event.name === "submap" && !root.hasCachedBinds()) {
        root.retryCount = 0
        root.refresh()
      }
    }
  }
}
