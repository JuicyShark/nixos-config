import QtQuick
import "../theme" as ThemeCfg

Item {
  id: root

  required property var modelData
  required property color escapeAccent

  readonly property bool isExit: !!modelData.isExit

  readonly property color keyTextColor: isExit
    ? root.escapeAccent
    : ThemeCfg.Theme.keyTextColor

  readonly property color actionTextColor: isExit
    ? Qt.lighter(root.escapeAccent, 1.46)
    : ThemeCfg.Theme.textPrimary

  readonly property string comboText: String((modelData && modelData.combo) || "")
  readonly property string actionText: String((modelData && modelData.action) || "")
  readonly property string iconText:   String((modelData && modelData.icon)   || "")

  readonly property var tokenAliases: ({
    left: "←", right: "→", up: "↑", down: "↓",
    control: "CTRL", ctrl: "CTRL", shift: "SHIFT",
    alt: "ALT", super: "SUPER", meta: "META", escape: "ESC",
    bracketleft: "[", bracketright: "]",
    backspace: "⌫", delete: "DEL", return: "↵",
    tab: "⇥", space: "SPC", print: "PRT",
    minus: "-", equal: "=", comma: ",", period: ".",
    semicolon: ";", apostrophe: "'", grave: "`",
    slash: "/", backslash: "\\",
    kp_enter: "↵", kp_plus: "+", kp_minus: "-",
    page_up: "PgUp", page_down: "PgDn",
    home: "Home", end: "End",
    insert: "Ins", caps_lock: "CAPS",
    f1: "F1", f2: "F2", f3: "F3", f4: "F4",
    f5: "F5", f6: "F6", f7: "F7", f8: "F8",
    f9: "F9", f10: "F10", f11: "F11", f12: "F12",
  })
  readonly property var comboTokens: comboTokenList(root.comboText)

  readonly property int actionFontSize: 16
  readonly property int tokenFontSize: 14
  readonly property int tokenGap: 4

  function comboTokenList(comboText) {
    const raw = String(comboText || "")
      .split(/\s*\+\s*/)
      .map((part) => String(part || "").trim())
      .filter((part) => part.length > 0)
    if (raw.length === 0) return ["?"]
    return raw.map((part) => root.tokenAliases[part.toLowerCase()] || part.toUpperCase())
  }

  Rectangle {
    anchors.fill: parent
    radius: 10
    color: root.isExit ? ThemeCfg.Theme.cardExitColor : ThemeCfg.Theme.cardColor
    border.width: 1
    border.color: root.isExit ? root.escapeAccent : ThemeCfg.Theme.cardBorderColor
    opacity: root.isExit ? 0.94 : 1.0

    Rectangle {
      visible: root.isExit
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 3
      radius: 2
      color: root.escapeAccent
    }
  }

  // ── shortcut capsule ─────────────────────────────────────────────────────

  Rectangle {
    id: keyPill
    anchors.left: parent.left
    anchors.leftMargin: root.isExit ? 13 : 10
    anchors.verticalCenter: parent.verticalCenter
    width: Math.max(72, Math.min(Math.floor(parent.width * 0.36), keySequence.width + 24))
    height: Math.min(parent.height - 16, 34)
    radius: 7
    color: Qt.rgba(
      root.keyTextColor.r,
      root.keyTextColor.g,
      root.keyTextColor.b,
      root.isExit ? 0.16 : 0.12,
    )
    border.width: 1
    border.color: Qt.rgba(
      root.keyTextColor.r,
      root.keyTextColor.g,
      root.keyTextColor.b,
      root.isExit ? 0.48 : 0.28,
    )
    clip: true

    Row {
      id: keySequence
      spacing: root.tokenGap
      anchors.centerIn: parent

      Repeater {
        model: root.comboTokens

        delegate: Row {
          required property int index
          required property var modelData

          spacing: root.tokenGap

          Text {
            text: String(modelData || "")
            color: root.keyTextColor
            font.family: "monospace"
            font.pixelSize: root.tokenFontSize
            font.weight: Font.Bold
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            visible: index < (root.comboTokens.length - 1)
            text: "+"
            color: ThemeCfg.Theme.textMuted
            font.family: "monospace"
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }

  // ── action area ───────────────────────────────────────────────────────────

  Item {
    anchors.left: keyPill.right
    anchors.leftMargin: 11
    anchors.right: parent.right
    anchors.rightMargin: 12
    anchors.top: parent.top
    anchors.bottom: parent.bottom

    // Icon glyph (Nerd Font, optional)
    Text {
      id: iconLabel
      visible: root.iconText.length > 0
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: root.iconText
      color: root.isExit
        ? root.actionTextColor
        : Qt.lighter(root.actionTextColor, 1.16)
      font.pixelSize: root.actionFontSize
    }

    // Action label
    Text {
      anchors.left: iconLabel.visible ? iconLabel.right : parent.left
      anchors.leftMargin: iconLabel.visible ? 5 : 0
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      wrapMode: Text.NoWrap
      maximumLineCount: 1
      elide: Text.ElideRight
      clip: true
      text: root.actionText.length > 0 ? root.actionText : "(no action)"
      color: root.actionTextColor
      font.family: "sans-serif"
      font.pixelSize: root.actionFontSize
      font.weight: Font.DemiBold
      font.letterSpacing: 0
    }
  }
}
