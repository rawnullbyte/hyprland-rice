pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool wifiEnabled: true
    readonly property bool scanning: rescanProc.running

    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null

    readonly property bool connected: active !== null
    readonly property string ssid: active?.ssid ?? "Not Connected"
    readonly property int signalStrength: active?.signalStrength ?? 0

    property bool bluetoothConnected: false
    property string bluetoothDeviceName: "Not Connected"
    property string bluetoothDeviceAddress: ""

    property var savedNetworks: []
    property bool pollingActive: true

    function toggleWifi(): void {
        const cmd = wifiEnabled ? "off" : "on"
        toggleProc.command = ["nmcli", "radio", "wifi", cmd]
        toggleProc.running = true
    }

    function rescanWifi(): void { rescanProc.running = true }

    function connectToNetwork(ssidStr: string, password: string): void {
        if (!ssidStr || ssidStr.trim().length === 0) return
        const bad = [";", "`", "$", "|", "&", "\n", "\r", "\\"]
        for (let i = 0; i < bad.length; i++) {
            if (ssidStr.includes(bad[i])) return
        }
        if (password && password.length > 0) {
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssidStr, "password", password]
        } else {
            connectProc.command = ["nmcli", "connection", "up", "id", ssidStr]
        }
        connectProc.running = true
    }

    function disconnectFromNetwork(): void {
        if (active) {
            discProc.command = ["nmcli", "connection", "down", active.ssid]
            discProc.running = true
        }
    }

    function updateBluetoothStatus(): void { btStatusProc.running = true }

    Process {
        id: monitorProc
        running: true
        command: ["nmcli", "m"]
        stdout: SplitParser { onRead: getNetworks.running = true }
    }

    Process {
        id: wifiStatusProc
        running: true
        command: ["nmcli", "radio", "wifi"]
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process { id: toggleProc; onExited: { wifiStatusProc.running = true; getNetworks.running = true } }

    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: getNetworks.running = true
    }

    Process {
        id: connectProc
        stdout: SplitParser { onRead: getNetworks.running = true }
        onExited: getNetworks.running = true
    }

    Process { id: discProc; stdout: SplitParser { onRead: getNetworks.running = true } }

    Process {
        id: savedProc
        command: ["nmcli", "-g", "NAME", "connection", "show"]
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: StdioCollector {
            onStreamFinished: root.savedNetworks = text.trim().split('\n').filter(n => n.length > 0)
        }
    }

    Process {
        id: btStatusProc
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n').filter(l => l.length > 0)
                if (lines.length > 0 && lines[0].startsWith('Device')) {
                    const parts = lines[0].split(' ')
                    if (parts.length >= 3) {
                        root.bluetoothDeviceAddress = parts[1]
                        root.bluetoothDeviceName = parts.slice(2).join(' ')
                        root.bluetoothConnected = true
                    }
                } else {
                    root.bluetoothConnected = false
                    root.bluetoothDeviceName = "Not Connected"
                    root.bluetoothDeviceAddress = ""
                }
            }
        }
    }

    Process {
        id: getNetworks
        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "__QS_PH__"
                const rep = new RegExp("\\\\:", "g")
                const rep2 = new RegExp(PLACEHOLDER, "g")

                const allNets = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":")
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3]?.replace(rep2, ":") ?? "",
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] ?? ""
                    }
                }).filter(n => n.ssid && n.ssid.length > 0)

                const netMap = new Map()
                for (const net of allNets) {
                    const existing = netMap.get(net.ssid)
                    if (!existing) {
                        netMap.set(net.ssid, net)
                    } else if (net.active && !existing.active) {
                        netMap.set(net.ssid, net)
                    } else if (!net.active && !existing.active && net.strength > existing.strength) {
                        netMap.set(net.ssid, net)
                    }
                }

                const nets = Array.from(netMap.values())
                const rNets = root.networks

                const destroyed = rNets.filter(rn => !nets.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid))
                for (const net of destroyed) rNets.splice(rNets.indexOf(net), 1).forEach(n => n.destroy())

                for (const net of nets) {
                    const match = rNets.find(n => n.frequency === net.frequency && n.ssid === net.ssid && n.bssid === net.bssid)
                    if (match) {
                        match.lastIpcObject = net
                    } else {
                        rNets.push(apComp.createObject(root, { lastIpcObject: net }))
                    }
                }
            }
        }
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
        readonly property string security: lastIpcObject.security
        readonly property bool isSecure: security.length > 0
    }

    Component { id: apComp; AccessPoint {} }

    Timer {
        interval: 5000
        running: root.pollingActive
        repeat: true
        onTriggered: root.updateBluetoothStatus()
    }

    Timer {
        interval: 10000
        running: root.pollingActive
        repeat: true
        onTriggered: savedProc.running = true
    }

    Component.onCompleted: {
        updateBluetoothStatus()
        savedProc.running = true
    }
}
