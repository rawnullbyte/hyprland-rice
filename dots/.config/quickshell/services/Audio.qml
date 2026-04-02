pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Properties for UI binding
    property real volume: 0.5
    property int percentage: 50
    property bool muted: false
    
    property real sourceVolume: 0.5
    property int sourcePercentage: 50
    property bool sourceMuted: false

    property real increaseStep: 0.03

    // Process for getting sink volume
    Process {
        id: getSinkVolProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        
        stdout: StdioCollector {
            id: sinkCollector
            onStreamFinished: {
                const output = sinkCollector.text
                const volMatch = output.match(/Volume: ([\d.]+)/)
                if (volMatch) {
                    const vol = parseFloat(volMatch[1])
                    if (!isNaN(vol)) {
                        root.volume = vol * 1.5
                        root.percentage = Math.round(root.volume * 100)
                    }
                }
                root.muted = output.includes("MUTED")
            }
        }
    }
    
    // Process for getting source volume
    Process {
        id: getSourceVolProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        
        stdout: StdioCollector {
            id: sourceCollector
            onStreamFinished: {
                const output = sourceCollector.text
                const volMatch = output.match(/Volume: ([\d.]+)/)
                if (volMatch) {
                    const vol = parseFloat(volMatch[1])
                    if (!isNaN(vol)) {
                        root.sourceVolume = vol * 1.5
                        root.sourcePercentage = Math.round(root.sourceVolume * 100)
                    }
                }
                root.sourceMuted = output.includes("MUTED")
            }
        }
    }
    
    // Timer to poll volume periodically
    Timer {
        id: pollTimer
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            if (!getSinkVolProc.running) getSinkVolProc.running = true
            if (!getSourceVolProc.running) getSourceVolProc.running = true
        }
    }

    // Public API for sink
    function setVolume(newVolume: real): void {
        const clamped = Math.max(0, Math.min(1.5, newVolume))
        volume = clamped
        percentage = Math.round(clamped * 100)
        muted = false
        
        const wpctlVolume = clamped / 1.5
        
        // Use execDetached for simple command execution
        Quickshell.execDetached({
            command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", String(wpctlVolume)]
        })
        
        // Refresh after a short delay
        refreshTimer.start()
    }

    function toggleMute(): void {
        Quickshell.execDetached({
            command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        })
        refreshTimer.start()
    }

    function increaseVolume(): void { 
        setVolume(volume + increaseStep) 
    }
    
    function decreaseVolume(): void { 
        setVolume(volume - increaseStep) 
    }

    // Public API for source
    function setSourceVolume(newVolume: real): void {
        const clamped = Math.max(0, Math.min(1.5, newVolume))
        sourceVolume = clamped
        sourcePercentage = Math.round(clamped * 100)
        sourceMuted = false
        
        const wpctlVolume = clamped / 1.5
        
        Quickshell.execDetached({
            command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", String(wpctlVolume)]
        })
        
        refreshTimer.start()
    }

    function toggleSourceMute(): void {
        Quickshell.execDetached({
            command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        })
        refreshTimer.start()
    }

    function increaseSourceVolume(): void { 
        setSourceVolume(sourceVolume + increaseStep) 
    }
    
    function decreaseSourceVolume(): void { 
        setSourceVolume(sourceVolume - increaseStep) 
    }

    // Timer to refresh after changes
    Timer {
        id: refreshTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            getSinkVolProc.running = true
            getSourceVolProc.running = true
        }
    }

    // Initial update
    Component.onCompleted: {
        getSinkVolProc.running = true
        getSourceVolProc.running = true
    }
}