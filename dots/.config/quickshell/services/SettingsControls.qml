pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool dndEnabled: false
    property bool isAvailable: false

    Component.onCompleted: {
        checkSwayNC.running = true
    }

    Process {
        id: checkSwayNC
        command: ["which", "swaync-client"]
        onExited: function(code) {
            root.isAvailable = code === 0
            if (root.isAvailable) {
                root.getDNDStatus()
                statusTimer.start()
            }
        }
    }

    function getDNDStatus() {
        if (!root.isAvailable) return
        getStatusProc.running = true
    }

    Process {
        id: getStatusProc
        command: ["swaync-client", "--get-dnd"]
        stdout: StdioCollector {
            onStreamFinished: function() {
                let output = text.trim().toLowerCase()
                root.dndEnabled = output === "true"
            }
        }
        onExited: function(code) {
            if (code !== 0) {
                console.warn("Failed to get DND status, exit code:", code)
            }
        }
    }

    function toggleDND() {
        if (!root.isAvailable) return
        
        let newState = !root.dndEnabled
        root.dndEnabled = newState
        
        let proc = Qt.createQmlObject('import Quickshell.Io; Process { command: [] }', root)
        proc.command = ["swaync-client", "--toggle-dnd"]
        proc.running = true
        
        // Connect to the exited signal properly
        let onExitedHandler = function(code) {
            refreshTimer.start()
            proc.destroy()
        }
        proc.exited.connect(onExitedHandler)
    }
    
    Timer {
        id: refreshTimer
        interval: 200
        onTriggered: root.getDNDStatus()
    }

    Timer {
        id: statusTimer
        interval: 5000
        running: root.isAvailable
        repeat: true
        onTriggered: root.getDNDStatus()
    }

    function getDNDIcon() {
        return root.dndEnabled ? "󰂚" : "󰂛"
    }

    function getDNDLabel() {
        return root.dndEnabled ? "DND On" : "DND Off"
    }
}