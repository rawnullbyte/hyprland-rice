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
    property int _currentRaw: 0
    property int _maxBrightness: 24242   // will be updated dynamically

    Component.onCompleted: {
        readCurrentBrightness()
        updateTimer.start()
    }

    function readCurrentBrightness(): void {
        if (_updating) return
        _updating = true
        readCurrentProc.running = true
    }

    function setBrightness(value: real): void {
        const clamped = Math.max(0.0, Math.min(1.0, value))
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

    // 1. Read current brightness (raw number)
    Process {
        id: readCurrentProc
        command: ["brightnessctl", "get"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const val = parseInt(data.trim(), 10)
                if (!isNaN(val)) {
                    root._currentRaw = val
                    readMaxProc.running = true   // now read max
                } else {
                    _updating = false
                }
            }
        }
        onExited: if (!_updating) _updating = false   // safety
    }

    // 2. Read max brightness
    Process {
        id: readMaxProc
        command: ["brightnessctl", "max"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const maxVal = parseInt(data.trim(), 10)
                if (!isNaN(maxVal) && maxVal > 0) {
                    root._maxBrightness = maxVal
                    root.brightness = Math.min(1.0, root._currentRaw / maxVal)
                }
                _updating = false
            }
        }
        onExited: _updating = false
    }

    // Set process
    Process {
        id: setProc
        running: false
        onExited: readCurrentBrightness()
    }

    // Increment / Decrement (percentage mode is very reliable)
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