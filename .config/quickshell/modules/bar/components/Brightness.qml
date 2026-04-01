import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../services" as QsServices

Item {
    id: root

    property var barWindow
    property var brightnessPopup

    readonly property var pywal: QsServices.Pywal
    readonly property var brightness: QsServices.Brightness
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property int percentage: brightness.percentage

    implicitWidth: brightnessRow.implicitWidth
    implicitHeight: 20

    RowLayout {
        id: brightnessRow
        anchors.centerIn: parent
        spacing: 3

        Text {
            id: brightnessIcon

            text: {
                if (percentage >= 75) return "󰃠"
                if (percentage >= 50) return "󰃟"
                if (percentage >= 25) return "󰃞"
                return "󰃝"
            }

            font.family: "Material Design Icons"
            font.pixelSize: 14

            color: {
                if (isHovered) return pywal.primary
                if (percentage >= 75) return Qt.rgba(pywal.warning.r, pywal.warning.g, pywal.warning.b, 0.85)
                return pywal.foreground
            }
        }

        Text {
            id: brightnessText

            text: percentage
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium

            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.7)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                brightness.increaseBrightness()
            } else {
                brightness.decreaseBrightness()
            }
        }
    }
}
