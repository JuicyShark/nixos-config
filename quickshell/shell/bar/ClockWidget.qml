import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import ".."

BarWidgetInner {
	id: root
	required property var bar;

	implicitHeight: layout.implicitHeight

	SystemClock {
		id: clock
		precision: tooltip.visible ? SystemClock.Seconds : SystemClock.Minutes;
	}

	BarButton {
		id: button
		anchors.fill: parent
		fillWindowWidth: true
		acceptedButtons: Qt.NoButton

   	ColumnLayout {
   		id: layout
   		spacing: 0

   		anchors {
   			right: parent.right
   			left: parent.left
   		}

   		Text {
   			Layout.alignment: Qt.AlignHCenter
   			text: {
   				const hours = clock.hours.toString().padStart(2, '0')
   				const minutes = clock.minutes.toString().padStart(2, '0')
   				return `${hours}\n${minutes}`
   			}
   			font.pointSize: 22
   			color: ShellGlobals.colors.text
   		}
   	}
	}

	property TooltipItem tooltip: TooltipItem {
		id: tooltip
		tooltip: bar.tooltip
		owner: root
		show: button.containsMouse

		Loader {
			active: tooltip.visible
			sourceComponent: Label {
				text: {
					// SystemClock can send an update slightly (<50ms) before the
					// time changes. We use its readout so the widget and tooltip match.
					const hours = clock.hours.toString().padStart(2, '0');
					const minutes = clock.minutes.toString().padStart(2, '0');
					const seconds = clock.seconds.toString().padStart(2, '0');

					return `${hours}:${minutes}:${seconds}\n` + new Date().toLocaleString(Qt.locale("en_US"), "dddd, MMMM d, yyyy");
				}
			}
		}
	}
}
