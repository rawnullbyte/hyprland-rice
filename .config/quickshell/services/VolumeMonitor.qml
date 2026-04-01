pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int percentage: 50
    property bool muted: false

    Timer {
        interval: 300
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: volProc.running = true
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                const volMatch = t.match(/Volume:\s*([\d.]+)/)
                if (volMatch) root.percentage = Math.round(parseFloat(volMatch[1]) * 100)
                root.muted = t.includes("MUTED")
            }
        }
    }
}
