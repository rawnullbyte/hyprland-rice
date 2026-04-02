pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string activeProfile: "balanced"
    property var availableProfiles: ["performance", "balanced", "power-saver"]
    property bool isAvailable: false
    property bool isSetting: false  // Add flag to track setting state

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
            onStreamFinished: {
                if (!root.isSetting) {  // Only update if not in the middle of setting
                    root.activeProfile = text.trim()
                }
            }
        }
    }

    function setProfile(profile: string): void {
        if (!isAvailable || !availableProfiles.includes(profile)) return
        
        // Immediately update UI for instant feedback
        root.isSetting = true
        root.activeProfile = profile
        
        // Run the set command
        setProc.command = ["powerprofilesctl", "set", profile]
        setProc.running = true
    }

    Process {
        id: setProc
        command: []
        onExited: {
            // Wait a tiny bit for the system to apply, then refresh
            refreshTimer.start()
        }
    }
    
    Timer {
        id: refreshTimer
        interval: 50  // Short delay to let system apply
        onTriggered: {
            // Refresh the actual state
            getProc.running = true
            // Reset setting flag after refresh completes
            resetFlagTimer.start()
        }
    }
    
    Timer {
        id: resetFlagTimer
        interval: 200  // Give enough time for getProc to complete
        onTriggered: {
            root.isSetting = false
        }
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
        running: root.isAvailable && !root.isSetting  // Don't auto-refresh while setting
        repeat: true
        onTriggered: {
            if (!root.isSetting) getProc.running = true
        }
    }
}