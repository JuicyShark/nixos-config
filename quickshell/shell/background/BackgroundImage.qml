import QtQuick
import Quickshell

Image {
	required property ShellScreen screen;
	source: Qt.resolvedUrl(screen.name == "DP-1" ? "5120x1440.png" : "1920x1080.png")
	asynchronous: false
	cache: false
}
