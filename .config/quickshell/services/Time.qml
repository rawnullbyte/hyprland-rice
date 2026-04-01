pragma Singleton

import Quickshell
import QtQuick 6.10

Singleton {
    id: root

    property date currentDate: new Date()

    readonly property string hours: {
        const h = currentDate.getHours()
        return h < 10 ? "0" + h : "" + h
    }
    readonly property string minutes: {
        const m = currentDate.getMinutes()
        return m < 10 ? "0" + m : "" + m
    }
    readonly property string seconds: {
        const s = currentDate.getSeconds()
        return s < 10 ? "0" + s : "" + s
    }

    readonly property string dateShort: Qt.formatDate(currentDate, "ddd, MMM d")
    readonly property string dateLong: Qt.formatDate(currentDate, "dddd, MMMM d")

    function format(fmt: string): string {
        return Qt.formatTime(currentDate, fmt)
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentDate = new Date()
    }
}
