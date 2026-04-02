pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real brightness: 0.5
    readonly property real level: brightness
    readonly property int percentage: Math.round(brightness * 100)

    readonly property string backlightPath: "/sys/class/backlight/intel_backlight/brightness"
    readonly property string maxBrightnessPath: "/sys/class/backlight/intel_backlight/max_brightness"

    property int currentValue: 0
    property int maxValue: 255

    Component.onCompleted: {
        readMaxBrightness()
        readBrightness()
        updateTimer.start()
    }

    function readMaxBrightness(): void { maxProc.running = true }
    function readBrightness(): void { curProc.running = true }

    function setBrightness(value: real): void {
        const clamped = Math.max(0, Math.min(1, value))
        brightness = clamped
        const pct = Math.round(clamped * 100)
        setProc.command = ["brightnessctl", "set", pct + "%"]
        setProc.running = true
    }

    function increaseBrightness(): void {
        brightness = Math.min(1, brightness + 0.05)
        incProc.running = true
    }

    function decreaseBrightness(): void {
        brightness = Math.max(0, brightness - 0.05)
        decProc.running = true
    }

    Process {
        id: maxProc
        command: ["cat", maxBrightnessPath]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const v = parseInt(data.trim())
                if (!isNaN(v) && v > 0) maxValue = v
            }
        }
    }

    Process {
        id: curProc
        command: ["cat", backlightPath]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const v = parseInt(data.trim())
                if (!isNaN(v)) {
                    currentValue = v
                    brightness = maxValue > 0 ? v / maxValue : 0
                }
            }
        }
    }

    Process { id: setProc; running: false }
    Process { id: incProc; command: ["brightnessctl", "-q", "set", "+5%"]; running: false }
    Process { id: decProc; command: ["brightnessctl", "-q", "set", "5%-"]; running: false }

    Timer {
        id: updateTimer
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: readBrightness()
    }
}
