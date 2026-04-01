pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property bool debugMode: Quickshell.env("QS_DEBUG") === "1"

    readonly property int levelTrace: 0
    readonly property int levelDebug: 1
    readonly property int levelInfo: 2
    readonly property int levelWarn: 3
    readonly property int levelError: 4

    property int minLevel: debugMode ? levelDebug : levelInfo

    function trace(comp: string, msg: string): void {
        if (levelTrace >= minLevel) console.log("[TRACE][" + comp + "]", msg)
    }
    function debug(comp: string, msg: string): void {
        if (levelDebug >= minLevel) console.log("[DEBUG][" + comp + "]", msg)
    }
    function info(comp: string, msg: string): void {
        if (levelInfo >= minLevel) console.log("[INFO][" + comp + "]", msg)
    }
    function warn(comp: string, msg: string): void {
        if (levelWarn >= minLevel) console.warn("[WARN][" + comp + "]", msg)
    }
    function error(comp: string, msg: string): void {
        if (levelError >= minLevel) console.error("[ERROR][" + comp + "]", msg)
    }
}
