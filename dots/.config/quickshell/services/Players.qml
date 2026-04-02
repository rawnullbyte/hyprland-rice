pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick 6.10

Singleton {
    id: root

    readonly property var list: Mpris.players.values

    property var active: {
        for (var i = 0; i < list.length; i++) {
            if (list[i]?.isPlaying) return list[i]
        }
        return list[0] ?? null
    }

    // Watch for property changes on the active player
    Connections {
        target: root.active
        enabled: root.active !== null
        function onPositionChanged() { 
            root.activeChanged()
        }
        function onLengthChanged() { 
            root.activeChanged()
        }
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { 
            root.updateActivePlayer()
        }
    }

    function updateActivePlayer(): void {
        var newActive = null
        for (var i = 0; i < list.length; i++) {
            if (list[i]?.isPlaying) { 
                newActive = list[i]
                break
            }
        }
        if (!newActive && list.length > 0) newActive = list[0]
        if (active !== newActive) {
            active = newActive
        }
    }

    Timer {
        interval: 1000
        running: list.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.updateActivePlayer()
            if (active) {
                let pos = active.position
            }
        }
    }
}