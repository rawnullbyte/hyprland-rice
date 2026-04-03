pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real brightness: 0.5
    readonly property real level: brightness
    readonly property int percentage: Math.round(brightness * 100)

    property bool _updating: false

    Component.onCompleted: {
        readCurrentBrightness()
        updateTimer.start()
    }

    function readCurrentBrightness(): void {
        if (_updating) return
        _updating = true
        readProc.running = true
    }

    function setBrightness(value: real): void {
        const clamped = Math.max(0, Math.min(1, value))
        brightness = clamped
        const pct = Math.round(clamped * 100)
        setProc.command = ["brightnessctl", "-q", "set", pct + "%"]
        setProc.running = true
    }

    function increaseBrightness(): void {
        brightness = Math.min(1.0, brightness + 0.05)
        incProc.running = true
    }

    function decreaseBrightness(): void {
        brightness = Math.max(0.0, brightness - 0.05)
        decProc.running = true
    }

    Process {
        id: readProc
        command: ["brightnessctl", "-q", "get"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                _updating = false
            }
        }

        onExited: _updating = false
    }

    Process {
        id: setProc
        running: false
        onExited: readCurrentBrightness()
    }

    Process {
        id: incProc
        command: ["brightnessctl", "-q", "set", "+5%"]
        running: false
        onExited: readCurrentBrightness()
    }

    Process {
        id: decProc
        command: ["brightnessctl", "-q", "set", "5%-"]
        running: false
        onExited: readCurrentBrightness()
    }

    Timer {
        id: updateTimer
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: readCurrentBrightness()
    }
}