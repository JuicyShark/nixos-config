import QtQuick
import "../lib/DisplayModel.js" as DisplayModel
import "../theme" as ThemeCfg

Rectangle {
  id: root

  // ── required inputs ───────────────────────────────────────────────────────

  required property string submap
  // Grouped bind model from HyprBindsService:
  //   [ { category: string, isExitGroup: bool, binds: NormalizedBind[] } ]
  required property var groups
  required property bool loading
  required property string errorText
  required property bool usingCache
  required property int maxHeight

  // ── internal theme aliases ────────────────────────────────────────────────

  property color submapAccent: ThemeCfg.Theme.submapAccent
  property color escapeAccent: ThemeCfg.Theme.escapeAccent

  // ── layout constants ──────────────────────────────────────────────────────

  readonly property int maxGridColumns: Math.max(1, ThemeCfg.Theme.gridMaxColumns)
  readonly property int minGridColumns: Math.max(1, Math.min(maxGridColumns, ThemeCfg.Theme.gridMinColumns))
  readonly property int twoColumnThreshold: Math.max(1, ThemeCfg.Theme.gridTwoColumnThreshold)
  readonly property int fourColumnThreshold: Math.max(1, ThemeCfg.Theme.gridFourColumnThreshold)
  readonly property int minCardWidth: Math.max(140, ThemeCfg.Theme.gridMinCardWidth)
  readonly property int effectiveCardHeight: ThemeCfg.Theme.compactMode
    ? Math.max(28, ThemeCfg.Theme.compactCardHeight)
    : Math.max(40, ThemeCfg.Theme.gridMinCardHeight)
  readonly property int headerH: Math.max(20, ThemeCfg.Theme.groupHeaderHeight)
  readonly property int submapHeaderH: Math.max(24, ThemeCfg.Theme.submapHeaderHeight)

  // ── bind / row counts ─────────────────────────────────────────────────────

  readonly property int bindCount: DisplayModel.bindCount(root.groups)

  // ── column calculation ────────────────────────────────────────────────────

  readonly property int visibleColumns: DisplayModel.columnsForWidth(
    root.width,
    root.bindCount,
    root.minGridColumns,
    root.maxGridColumns,
    root.twoColumnThreshold,
    root.fourColumnThreshold,
    root.minCardWidth,
    ThemeCfg.Theme.gridOuterMargin,
  )

  // ── display row model ─────────────────────────────────────────────────────

  // Flat array of row descriptors for the ListView:
  //   { type: "header", label: string }
  //   { type: "bindrow", binds: NormalizedBind[] }
  readonly property var displayRows: DisplayModel.buildRowModel(root.groups, root.visibleColumns, root.submap)

  // ── height calculation ────────────────────────────────────────────────────

  readonly property int spacerH: ThemeCfg.Theme.groupSpacerHeight
  readonly property var heightMetrics: ({
    submapHeaderH: root.submapHeaderH,
    outerMargin: ThemeCfg.Theme.gridOuterMargin,
    footerReserve: ThemeCfg.Theme.gridFooterReserve,
    spacerH: root.spacerH,
    headerH: root.headerH,
    cardH: root.effectiveCardHeight,
  })
  readonly property var panelMeasurements: DisplayModel.panelMeasurements(
    root.groups,
    root.visibleColumns,
    root.submap,
    root.maxHeight,
    root.heightMetrics,
  )
  readonly property bool contentOverflows: root.panelMeasurements.overflows

  // ── root rectangle ────────────────────────────────────────────────────────

  radius: ThemeCfg.Theme.panelRadius
  color: ThemeCfg.Theme.panelColor
  border.width: 1
  border.color: Qt.rgba(
    ThemeCfg.Theme.borderColor.r,
    ThemeCfg.Theme.borderColor.g,
    ThemeCfg.Theme.borderColor.b,
    0.55,
  )
  implicitHeight: root.panelMeasurements.clamped

  Rectangle {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: root.submapHeaderH + ThemeCfg.Theme.gridOuterMargin * 2
    radius: ThemeCfg.Theme.panelRadius
    color: Qt.rgba(
      ThemeCfg.Theme.surfaceColor.r,
      ThemeCfg.Theme.surfaceColor.g,
      ThemeCfg.Theme.surfaceColor.b,
      0.34,
    )
  }

  // ── submap identity strip ─────────────────────────────────────────────────

  Item {
    id: submapHeader

    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.topMargin: ThemeCfg.Theme.gridOuterMargin
    anchors.leftMargin: ThemeCfg.Theme.gridOuterMargin
    anchors.rightMargin: ThemeCfg.Theme.gridOuterMargin
    height: root.submapHeaderH

    Rectangle {
      anchors.fill: parent
      radius: ThemeCfg.Theme.submapHeaderCapsuleRadius
      color: Qt.rgba(
        ThemeCfg.Theme.surfaceColor.r,
        ThemeCfg.Theme.surfaceColor.g,
        ThemeCfg.Theme.surfaceColor.b,
        0.72,
      )
      border.width: 1
      border.color: Qt.rgba(
        ThemeCfg.Theme.submapAccent.r,
        ThemeCfg.Theme.submapAccent.g,
        ThemeCfg.Theme.submapAccent.b,
        0.22,
      )
    }

    Row {
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: 14
      spacing: 10

      Rectangle {
        width: 8
        height: 8
        radius: 4
        color: root.submapAccent
        anchors.verticalCenter: parent.verticalCenter
        opacity: 1.0
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
          text: "HYPRLAND SUBMAP"
          color: ThemeCfg.Theme.textMuted
          font.pixelSize: 9
          font.weight: Font.Bold
          font.letterSpacing: 1.2
          opacity: 0.78
        }

        Text {
          text: String(root.submap || "").toUpperCase()
          color: root.submapAccent
          font.pixelSize: 18
          font.weight: Font.DemiBold
          font.letterSpacing: 0.4
          opacity: 0.98
        }
      }
    }

    // Bind count — a compact status chip, not another loose label.
    Rectangle {
      visible: !root.loading && root.errorText.length === 0
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      width: bindMetric.width + 18
      height: 26
      radius: 7
      color: Qt.rgba(
        root.submapAccent.r,
        root.submapAccent.g,
        root.submapAccent.b,
        0.12,
      )

      Text {
        id: bindMetric
        anchors.centerIn: parent
        text: String(root.bindCount) + " BINDS"
        color: root.submapAccent
        font.family: "monospace"
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 0.6
      }
    }
  }

  // ── content area (bind rows + headers) ────────────────────────────────────

  Item {
    id: contentArea

    anchors.top: submapHeader.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.leftMargin: ThemeCfg.Theme.gridOuterMargin
    anchors.rightMargin: ThemeCfg.Theme.gridOuterMargin
    anchors.bottomMargin: ThemeCfg.Theme.gridFooterReserve
    anchors.topMargin: 8

    ListView {
      id: rowList

      anchors.fill: parent
      clip: true
      model: root.displayRows
      spacing: 0
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick

      // Delegate: plain Item containing a GroupHeader or BindRow depending on
      // row type. Both are instantiated directly with property bindings so
      // QML's dependency tracker works correctly — no Loader / onLoaded /
      // Qt.binding() indirection needed.
      delegate: Item {
        id: rowDelegate

        required property var modelData
        required property int index

        readonly property bool isHeader: modelData.type === "header"

        width: rowList.width
        height: isHeader
          ? root.headerH + (rowDelegate.index > 0 ? root.spacerH : 0)
          : root.effectiveCardHeight

        GroupHeader {
          anchors.fill: parent
          visible: rowDelegate.isHeader
          label: rowDelegate.isHeader ? (String(rowDelegate.modelData.label || "")) : ""
        }

        BindRow {
          anchors.fill: parent
          visible: !rowDelegate.isHeader
          rowBinds: (!rowDelegate.isHeader && rowDelegate.modelData.binds)
            ? rowDelegate.modelData.binds
            : []
          totalColumns: root.visibleColumns
          escapeAccent: root.escapeAccent
        }
      }
    }
  }

  // ── footer ────────────────────────────────────────────────────────────────

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: ThemeCfg.Theme.footerHeight
    radius: ThemeCfg.Theme.panelRadius
    color: Qt.rgba(
      ThemeCfg.Theme.surfaceColor.r,
      ThemeCfg.Theme.surfaceColor.g,
      ThemeCfg.Theme.surfaceColor.b,
      0.30,
    )

    Rectangle {
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 1
      color: ThemeCfg.Theme.borderColor
      opacity: 0.65
    }

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      text: "SUBMAP INPUT ACTIVE"
      color: ThemeCfg.Theme.textMuted
      opacity: 0.72
      font.pixelSize: 9
      font.weight: Font.Bold
      font.letterSpacing: 1.05
    }
  }

  FooterStatus {
    visible: true
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: 14
    anchors.bottomMargin: 8

    width: Math.max(120, parent.width * 0.45)
    elide: Text.ElideLeft
    horizontalAlignment: Text.AlignRight

    loading: root.loading
    errorText: root.errorText
    usingCache: root.usingCache
    bindCount: root.bindCount
    overflowing: root.contentOverflows
  }

}
