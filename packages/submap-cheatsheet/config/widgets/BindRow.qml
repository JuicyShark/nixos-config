import QtQuick
import "../theme" as ThemeCfg

Item {
  id: root

  required property var rowBinds
  required property int totalColumns
  required property color escapeAccent

  readonly property int bindCount: (root.rowBinds && root.rowBinds.length) ? root.rowBinds.length : 0
  readonly property int placeholderCount: Math.max(0, root.totalColumns - root.bindCount)
  readonly property int columnGap: ThemeCfg.Theme.gridColumnGap
  readonly property real cellWidth: root.totalColumns > 0
    ? Math.max(0, (root.width - (root.totalColumns - 1) * root.columnGap) / root.totalColumns)
    : root.width

  readonly property bool isExitRow: {
    if (!root.rowBinds) return false
    for (let i = 0; i < root.rowBinds.length; i++) {
      if (root.rowBinds[i] && root.rowBinds[i].isExit) return true
    }
    return false
  }

  // A quiet divider keeps the escape route visibly separate from the commands.
  Rectangle {
    visible: root.isExitRow
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 2
    color: root.escapeAccent
    opacity: 0.45
  }

  Row {
    anchors.fill: parent
    spacing: root.columnGap

    Repeater {
      model: root.rowBinds

      delegate: Item {
        id: cardWrapper

        required property var modelData
        required property int index

        width: root.cellWidth
        height: root.height

        BindCard {
          id: card
          anchors.fill: parent
          anchors.topMargin: 4
          anchors.bottomMargin: 2
          modelData: cardWrapper.modelData
          escapeAccent: root.escapeAccent
        }
      }
    }

    Repeater {
      model: root.placeholderCount

      delegate: Item {
        required property int index

        width: root.cellWidth
        height: root.height
      }
    }
  }
}
