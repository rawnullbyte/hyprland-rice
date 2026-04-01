import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import "../../../services" as QsServices

Item {
    id: root

    property var barWindow
    property var volumePopup

    readonly property var pywal: QsServices.Pywal
    readonly property var volumeMonitor: QsServices.VolumeMonitor
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool isMuted: volumeMonitor.muted
    readonly property int percentage: volumeMonitor.percentage

    implicitWidth: volumeRow.implicitWidth
    implicitHeight: 20

    RowLayout {
        id: volumeRow
        anchors.centerIn: parent
        spacing: 3

        Text {
            id: volumeIcon

            text: {
                if (isMuted) return "󰖁"
                if (percentage >= 70) return "󰕾"
                if (percentage >= 30) return "󰖀"
                return "󰕿"
            }

            font.family: "Material Design Icons"
            font.pixelSize: 14

            color: {
                if (isMuted) return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.35)
                if (isHovered) return pywal.primary
                return pywal.foreground
            }
        }

        Text {
            id: volumeText

            text: percentage
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium

            color: {
                if (isMuted) return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.35)
                return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.7)
            }
        }
    }

    Process { id: volUp; command: ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", "1%+"]; running: false }
    Process { id: volDown; command: ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", "1%-"]; running: false }
    Process { id: volMute; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]; running: false }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                volUp.running = true
            } else {
                volDown.running = true
            }
        }

        onClicked: volMute.running = true
    }
}
