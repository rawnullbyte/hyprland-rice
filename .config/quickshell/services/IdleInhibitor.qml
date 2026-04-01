pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool inhibited: false
    property int inhibitorPid: -1

    onInhibitedChanged: {
        if (inhibited) {
            enableProc.running = true
        } else {
            disableProc.running = true
        }
    }

    Process {
        id: enableProc
        command: ["/bin/sh", "-c", "systemd-inhibit --what=idle --who=QuickShell --why='Caffeine mode' sleep infinity & echo $!"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const pid = parseInt(data.trim())
                if (!isNaN(pid) && pid > 0) root.inhibitorPid = pid
            }
        }
    }

    Process {
        id: disableProc
        command: ["/bin/sh", "-c", root.inhibitorPid > 0 ?
            `kill ${root.inhibitorPid} 2>/dev/null; pkill -f 'systemd-inhibit.*QuickShell' 2>/dev/null; true` :
            "pkill -f 'systemd-inhibit.*QuickShell' 2>/dev/null; true"]
        running: false
        onExited: root.inhibitorPid = -1
    }
}
