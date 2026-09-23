import QtQuick
import "../theme" as ThemeCfg

Text {
  id: root

  required property bool loading
  required property string errorText
  required property bool usingCache
  required property int bindCount
  required property bool overflowing

  readonly property string normalizedError: String(root.errorText || "").trim().replace(/\s+/g, " ")

  text: root.loading
    ? "Loading"
    : (root.errorText.length > 0
        ? ("Error: " + root.normalizedError)
        : (root.usingCache
            ? (String(root.bindCount) + " binds (cached)")
            : (root.overflowing
                ? "SCROLL FOR MORE"
                : "LIVE")))

  color: root.errorText.length > 0 ? ThemeCfg.Theme.textError : ThemeCfg.Theme.textMuted
  font.pixelSize: 10
  font.weight: Font.Bold
  font.letterSpacing: 0.8
}
