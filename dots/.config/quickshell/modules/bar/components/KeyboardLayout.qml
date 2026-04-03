import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var pywal
    property string currentLayout: "US"

    implicitWidth: layoutRow.implicitWidth + 16
    implicitHeight: layoutRow.implicitHeight + 8

    readonly property bool isHovered: mouseArea.containsMouse

    // Process to get keyboard layout
    Process {
        id: hyprProcess
        command: ["hyprctl", "devices", "-j"]

        // Fixed: Use proper function with parameters instead of deprecated injection
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && stdout.text.length > 0) {
                processOutput(stdout.text)
            }
        }

        stdout: StdioCollector {}
    }

    function processOutput(text) {
        try {
            const data = JSON.parse(text)
            if (data.keyboards && data.keyboards.length > 0) {
                // Prefer the main keyboard
                let kb = data.keyboards.find(k => k.main === true) || data.keyboards[0]
                let keymap = kb.active_keymap || "us"
                let newLayout = keymap.substring(0, 2).toUpperCase()

                if (newLayout !== root.currentLayout) {
                    root.currentLayout = newLayout
                }
            }
        } catch (e) {
            // Silently ignore parsing errors
        }
    }

    // Polling timer
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: hyprProcess.running = true
    }

    Component.onCompleted: {
        hyprProcess.running = true
    }

    Row {
        id: layoutRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.currentLayout
            color: isHovered
                ? (root.pywal ? root.pywal.primary : "#ffffff")
                : (root.pywal ? root.pywal.foreground : "#cccccc")

            font.pixelSize: 13
            font.weight: Font.Medium        // Less bold than Font.Bold
            font.family: "Inter"
            font.letterSpacing: 0.8

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -8
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            const proc = Qt.createQmlObject(
                `import Quickshell
                 import Quickshell.Io
                 Process {
                     command: ["hyprctl", "switchxkblayout", "all", "next"]
                 }`,
                root
            )
            proc.running = true
        }
    }
}