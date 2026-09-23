pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: theme

  // ── Stylix-derived palette ────────────────────────────────────────────────
  // Written by home-manager from config.lib.stylix.colors at
  // $XDG_CONFIG_HOME/submap-cheatsheet/palette.json. Every color property
  // below falls back to a hard-coded value if the file is missing or malformed
  // so the cheatsheet still renders standalone.
  property var _palette: ({})

  function _color(key, fallback) {
    const v = theme._palette[key]
    return (typeof v === "string" && v.length > 0) ? v : fallback
  }

  FileView {
    path: {
      const xdgConfig = Quickshell.env("XDG_CONFIG_HOME")
      const home = Quickshell.env("HOME")
      const base = (xdgConfig && xdgConfig.length > 0) ? xdgConfig
                 : (home ? home + "/.config" : "")
      return base.length > 0 ? base + "/submap-cheatsheet/palette.json" : ""
    }
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        theme._palette = JSON.parse(this.text())
      } catch (e) {
        theme._palette = {}
      }
    }
    onLoadFailed: theme._palette = {}
  }

  // This is a command deck, not a dialog.  A 32:9 panel has room to make
  // shortcut/action pairs comfortably scannable without obscuring the work.
  property int widgetMaxWidth: 2240
  property real widgetUltrawideWidthFraction: 0.56
  property real widgetRegularWidthFraction: 0.82
  property real ultrawideAspectThreshold: 2.4
  // Sparse maps still need presence on a 5120px-wide panel.  This preserves a
  // shorter deck without shrinking it into a conventional-dialog footprint.
  property real widgetThreeColumnWidthFactor: 0.88
  property int widgetScreenMargin: 72
  // By default the overlay follows the focused Hyprland monitor.
  property bool showOnAllScreens: false
  // An explicit monitor takes precedence over focus and the all-screen mode.
  property string targetMonitor: Quickshell.env("SUBMAP_CHEATSHEET_MONITOR") || ""
  // Gap between the bottom screen edge and the panel (panel is bottom-anchored).
  property int widgetBottomMargin: 18
  // Avoid flashing the deck for one-shot submap actions such as a quick app launch.
  property int submapRevealDelayMs: 180
  property int panelRadius: 18
  property int submapHeaderCapsuleRadius: 11
  property real widgetMaxScreenFraction: 0.50
  property int widgetMinHeight: 178

  // Grid / layout
  property int gridOuterMargin: 14
  property int gridFooterReserve: 32
  property int gridMinColumns: 2
  property int gridMaxColumns: 5
  property int gridTwoColumnThreshold: 8
  property int gridFourColumnThreshold: 20
  property int gridMinCardWidth: 274
  property int gridColumnGap: 8

  // Card row height.  compactMode uses compactCardHeight instead of gridMinCardHeight.
  property bool compactMode: true
  property int gridMinCardHeight: 42
  property int compactCardHeight: 58

  // Section header height inserted between named bind categories.
  property int groupHeaderHeight: 32
  // Extra vertical gap inserted above every non-first group header.
  property int groupSpacerHeight: 8

  // Submap name strip rendered at the top of the panel.
  property int submapHeaderHeight: 58
  property int footerHeight: 28

  // Separator glyph between the key chip area and the action label.
  property string bindSeparator: "→"

  property color submapAccent: theme._color("submapAccent", "#80CBC4")
  property color escapeAccent: theme._color("escapeAccent", "#EC5F67")

  // 70% opacity so Hyprland blur composites through the panel background.
  // Add to hyprland.conf: layerrule = blur, submap-cheatsheet
  //                       layerrule = ignorezero, submap-cheatsheet
  property color panelColor: theme._color("panel", "#B3050505")
  property color cardColor: theme._color("card", "#801B1F23")
  property color cardExitColor: theme._color("cardExit", "#402B171B")

  property color keyTextColor: theme._color("keyText", "#98C379")
  property real keyAreaFraction: 0.19
  property int keyAreaMinWidth: 64

  property color textPrimary: theme._color("textPrimary", "#9AA5B4")
  property color textMuted: theme._color("textMuted", "#A6B0BB")
  property color textError: theme._color("textError", "#EC5F67")
  // Opaque inner-surface colour (base01) used behind the submap header chip.
  property color surfaceColor: theme._color("surface", "#1B1F23")
  // Subtle neutral panel border (base03) — replaces the accent-tinted border
  // so the chrome reads as soft chrome, not a colored frame.
  property color borderColor: theme._color("border", "#3A4150")
  property color cardBorderColor: theme._color("cardBorder", "#45505B6B")
}
