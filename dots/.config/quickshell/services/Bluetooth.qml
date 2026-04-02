pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool powered: false
    property bool discovering: false
    property var devices: []

    readonly property var connectedDevices: devices.filter(d => d.connected)
    readonly property bool connected: connectedDevices.length > 0
    readonly property string deviceName: connectedDevices.length > 0 ? connectedDevices[0].name : ""

    function togglePower(): void {
        if (powered) {
            powerOffProc.running = true
        } else {
            powerOnProc.running = true
        }
    }

    function startScan(): void {
        scanStartProc.running = true
    }

    function connectDevice(address: string): void {
        connectProc.command = ["bluetoothctl", "connect", address]
        connectProc.running = true
    }

    function disconnectDevice(address: string): void {
        disconnectProc.command = ["bluetoothctl", "disconnect", address]
        disconnectProc.running = true
    }

    Process {
        id: infoProc
        running: true
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.powered = text.includes("Powered: yes")
        }
    }

    Process {
        id: powerOnProc
        command: ["bluetoothctl", "power", "on"]
        onExited: { infoProc.running = true; deviceListProc.running = true }
    }

    Process {
        id: powerOffProc
        command: ["bluetoothctl", "power", "off"]
        onExited: { root.powered = false; root.devices = [] }
    }

    Process {
        id: scanStartProc
        command: ["bluetoothctl", "scan", "on"]
        onExited: { root.discovering = true; scanStopTimer.start() }
    }

    Timer {
        id: scanStopTimer
        interval: 8000
        onTriggered: scanStopProc.running = true
    }

    Process {
        id: scanStopProc
        command: ["bluetoothctl", "scan", "off"]
        onExited: { root.discovering = false; deviceListProc.running = true }
    }

    Process {
        id: deviceListProc
        running: true
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n').filter(l => l.length > 0)
                const devs = []
                for (const line of lines) {
                    const parts = line.split(' ')
                    if (parts.length >= 3 && parts[0] === 'Device') {
                        devs.push({ address: parts[1], name: parts.slice(2).join(' '), connected: false })
                    }
                }
                root.devices = devs
                connCheckProc.running = true
            }
        }
    }

    Process {
        id: connCheckProc
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const connected = new Set()
                for (const line of text.trim().split('\n').filter(l => l.length > 0)) {
                    const parts = line.split(' ')
                    if (parts.length >= 2 && parts[0] === 'Device') connected.add(parts[1])
                }
                root.devices = root.devices.map(d => ({
                    address: d.address, name: d.name, connected: connected.has(d.address)
                }))
            }
        }
    }

    Process {
        id: connectProc
        command: []
        onExited: { deviceListProc.running = true; infoProc.running = true }
    }

    Process {
        id: disconnectProc
        command: []
        onExited: { deviceListProc.running = true; infoProc.running = true }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: { infoProc.running = true; deviceListProc.running = true }
    }
}
