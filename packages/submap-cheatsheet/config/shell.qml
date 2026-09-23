import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "lib/DisplayModel.js" as DisplayModel
import "services" as Services
import "theme" as ThemeCfg
import "widgets" as Widgets

Scope {
  id: root

  readonly property string shownSubmap: submapService.activeSubmap
  readonly property bool panelVisible: submapService.inSubmap
  // Hyprland exits many submaps immediately after a one-shot action. Delay the
  // visual reveal just long enough for those fast paths to stay unobtrusive.
  property bool revealReady: false

  readonly property var shownGroups: {
    return bindsService.bindsForSubmap(root.shownSubmap)
  }

  readonly property int shownBindCount: DisplayModel.bindCount(root.shownGroups)
  readonly property bool useNarrowWidth: shownBindCount > 0
    && shownBindCount < ThemeCfg.Theme.gridFourColumnThreshold

  // Frozen copies of display state updated only while the panel is visible.
  // Using restoreMode: Binding.RestoreNone keeps the last value when
  // panelVisible goes false, so the widget content stays stable for the full
  // duration of the exit animation instead of collapsing immediately.
  property var    _lastGroups:         []
  property string _lastSubmap:         ""
  property bool   _lastUseNarrowWidth: false

  Binding {
    when: root.revealReady
    restoreMode: Binding.RestoreNone
    target: root; property: "_lastGroups"; value: root.shownGroups
  }
  Binding {
    when: root.revealReady
    restoreMode: Binding.RestoreNone
    target: root; property: "_lastSubmap"; value: root.shownSubmap
  }
  Binding {
    when: root.revealReady
    restoreMode: Binding.RestoreNone
    target: root; property: "_lastUseNarrowWidth"; value: root.useNarrowWidth
  }

  Services.HyprSubmapService { id: submapService }
  Services.HyprBindsService  { id: bindsService  }

  onPanelVisibleChanged: {
    if (panelVisible) {
      revealReady = false
      revealDelay.restart()
    } else {
      revealDelay.stop()
      revealReady = false
    }
  }

  Component.onCompleted: {
    if (panelVisible) revealDelay.restart()
  }

  Timer {
    id: revealDelay
    interval: ThemeCfg.Theme.submapRevealDelayMs
    repeat: false
    onTriggered: root.revealReady = root.panelVisible
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData

      readonly property var hyprMonitor: Hyprland.monitorFor(modelData)
      readonly property bool isFocusedScreen: {
        const focused = Hyprland.focusedMonitor
        if (!focused) return true
        if (hyprMonitor) return hyprMonitor.id === focused.id
        return String(modelData && modelData.name) === String(focused.name)
      }
      readonly property bool isTargetScreen: String(modelData && modelData.name)
        === ThemeCfg.Theme.targetMonitor
      readonly property bool panelActive: root.revealReady
        && (ThemeCfg.Theme.targetMonitor.length > 0
          ? isTargetScreen
          : (ThemeCfg.Theme.showOnAllScreens || isFocusedScreen))
      readonly property int screenHeightPx: {
        const v = Number(modelData && modelData.height)
        return v > 0 ? Math.floor(v) : 1080
      }
      readonly property int screenWidthPx: {
        const v = Number(modelData && modelData.width)
        return v > 0 ? Math.floor(v) : 1920
      }
      readonly property bool isUltrawide: screenWidthPx / screenHeightPx
        >= ThemeCfg.Theme.ultrawideAspectThreshold
      readonly property real panelWidthFraction: isUltrawide
        ? ThemeCfg.Theme.widgetUltrawideWidthFraction
        : ThemeCfg.Theme.widgetRegularWidthFraction
      readonly property int panelWidth: Math.min(
        screenWidthPx - ThemeCfg.Theme.widgetScreenMargin,
        Math.floor(Math.min(
          screenWidthPx * panelWidthFraction,
          ThemeCfg.Theme.widgetMaxWidth
            * (root._lastUseNarrowWidth ? ThemeCfg.Theme.widgetThreeColumnWidthFactor : 1),
        )),
      )
      readonly property int widgetMaxHeight: Math.max(
        ThemeCfg.Theme.widgetMinHeight,
        Math.floor(screenHeightPx * ThemeCfg.Theme.widgetMaxScreenFraction),
      )

      // Compute panel target height directly from bind data.
      // We cannot use whichKey.implicitHeight here: reading a child's
      // implicitHeight inside a bottom-anchored Wayland surface creates a
      // feedback loop (surface grows → y shifts → child geometry re-evaluates
      // → implicitHeight re-evaluates → surface grows again).
      readonly property int shownPanelHeight: {
        const groups = root.shownGroups
        if (!Array.isArray(groups)) return ThemeCfg.Theme.widgetMinHeight

        const minC   = ThemeCfg.Theme.gridMinColumns
        const maxC   = ThemeCfg.Theme.gridMaxColumns
        const n      = root.shownBindCount
        const minCW  = Math.max(140, ThemeCfg.Theme.gridMinCardWidth)
        const cols   = DisplayModel.columnsForWidth(
          panelWidth,
          n,
          minC,
          maxC,
          ThemeCfg.Theme.gridTwoColumnThreshold,
          ThemeCfg.Theme.gridFourColumnThreshold,
          minCW,
          ThemeCfg.Theme.gridOuterMargin,
        )
        const cardH  = ThemeCfg.Theme.compactMode
          ? Math.max(28, ThemeCfg.Theme.compactCardHeight)
          : Math.max(40, ThemeCfg.Theme.gridMinCardHeight)
        const measurements = DisplayModel.panelMeasurements(
          groups,
          cols,
          root.shownSubmap,
          widgetMaxHeight,
          {
          submapHeaderH: Math.max(24, ThemeCfg.Theme.submapHeaderHeight),
          outerMargin: ThemeCfg.Theme.gridOuterMargin,
          footerReserve: ThemeCfg.Theme.gridFooterReserve,
          spacerH: ThemeCfg.Theme.groupSpacerHeight,
          headerH: Math.max(20, ThemeCfg.Theme.groupHeaderHeight),
          cardH: cardH,
          },
        )
        return measurements.clamped
      }

      readonly property int revealTargetHeight: shownPanelHeight

      screen: modelData
      visible: panelActive || revealWrapper.implicitHeight > 0
      color: "transparent"
      aboveWindows: true
      exclusionMode: ExclusionMode.Ignore
      focusable: false
      WlrLayershell.namespace: "submap-cheatsheet"
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.margins.bottom: ThemeCfg.Theme.widgetBottomMargin

      anchors { bottom: true }

      implicitWidth: panelWidth
      implicitHeight: revealWrapper.implicitHeight

      Item {
        id: panelRoot
        anchors.fill: parent
        clip: true

        Item {
          id: revealWrapper
          anchors.top: parent.top
          width: panelWidth
          implicitHeight: 0

          // Opacity softens content changes; Hyprland owns travel direction for
          // the layer via `animation = "slide bottom"`.
          opacity: panelActive ? 1.0 : 0.0
          Behavior on opacity {
            NumberAnimation {
              duration: panelActive ? 90 : 120
              easing.type: Easing.OutCubic
            }
          }

          // Height drives layer-shell geometry. On close we keep the last size
          // until the short fade completes, then collapse instantly so the
          // compositor's bottom slide is the only directional exit animation.
          readonly property real heightTarget: panelActive ? revealTargetHeight : 0

          onHeightTargetChanged: {
            if (heightTarget > 0) {
              closeGeometryTimer.stop()
              revealWrapper.implicitHeight = heightTarget
            } else if (revealWrapper.implicitHeight > 0) {
              closeGeometryTimer.restart()
            }
          }

          Timer {
            id: closeGeometryTimer
            interval: 125
            repeat: false
            onTriggered: revealWrapper.implicitHeight = 0
          }
        }

        Widgets.SubmapWhichKey {
          id: whichKey
          anchors.bottom: revealWrapper.bottom
          anchors.horizontalCenter: revealWrapper.horizontalCenter
          // Use frozen display state so content stays stable during exit animation.
          width: panelWidth
          maxHeight: widgetMaxHeight
          submap: root._lastSubmap
          groups: root._lastGroups
          loading: bindsService.loading
          errorText: bindsService.errorText
          usingCache: bindsService.usingCache
        }
      }
    }
  }
}
