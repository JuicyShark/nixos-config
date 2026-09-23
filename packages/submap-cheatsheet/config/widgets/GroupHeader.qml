import QtQuick
import "../theme" as ThemeCfg

// Full-width section header rendered between named bind categories.
Item {
  id: root

  required property string label

  Row {
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 4
    anchors.rightMargin: 4
    spacing: 8

    Rectangle {
      width: 5
      height: 5
      radius: 3
      color: ThemeCfg.Theme.submapAccent
      anchors.verticalCenter: parent.verticalCenter
      opacity: 0.9
    }

    Text {
      text: root.label.toUpperCase()
      color: ThemeCfg.Theme.submapAccent
      font.pixelSize: 12
      font.weight: Font.Bold
      font.letterSpacing: 1.1
      anchors.verticalCenter: parent.verticalCenter
      opacity: 0.95
    }
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1
    color: ThemeCfg.Theme.borderColor
    opacity: 0.65
  }
}
