pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string activeProfile: "balanced"
    property var availableProfiles: ["performance", "balanced", "power-saver"]
    property bool isAvailable: false

    Component.onCompleted: {
        checkProc.running = true
    }

    Process {
        id: checkProc
        command: ["which", "powerprofilesctl"]
        onExited: code => {
            root.isAvailable = code === 0
            if (root.isAvailable) getProc.running = true
        }
    }

    Process {
        id: getProc
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: root.activeProfile = text.trim()
        }
    }

    function setProfile(profile: string): void {
        if (!isAvailable || !availableProfiles.includes(profile)) return
        setProc.command = ["powerprofilesctl", "set", profile]
        setProc.running = true
    }

    Process {
        id: setProc
        command: []
        onExited: getProc.running = true
    }

    function getProfileIcon(profile: string): string {
        switch (profile) {
            case "performance": return "\uf093"
            case "balanced": return "\uf06c"
            case "power-saver": return "\uf0e7"
            default: return "\uf085"
        }
    }

    function getProfileLabel(profile: string): string {
        switch (profile) {
            case "performance": return "Performance"
            case "balanced": return "Balanced"
            case "power-saver": return "Power Saver"
            default: return profile
        }
    }

    Timer {
        interval: 5000
        running: root.isAvailable
        repeat: true
        onTriggered: getProc.running = true
    }
}
