pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10

Singleton {
    id: root

    property string homePath: ""
    readonly property string pywalPath: homePath + "/.cache/wal/colors.json"

    property color background: "#13120d"
    property color foreground: "#becbca"
    property color cursor: "#becbca"

    property color color0: "#13120d"
    property color color1: "#4F6858"
    property color color2: "#3E867D"
    property color color3: "#658676"
    property color color4: "#899470"
    property color color5: "#3D8686"
    property color color6: "#6F948E"
    property color color7: "#becbca"
    property color color8: "#858e8d"
    property color color9: "#4F6858"
    property color color10: "#3E867D"
    property color color11: "#658676"
    property color color12: "#899470"
    property color color13: "#3D8686"
    property color color14: "#6F948E"
    property color color15: "#becbca"

    readonly property color primary: color4
    readonly property color primaryContainer: Qt.rgba(color4.r, color4.g, color4.b, 0.2)
    readonly property color onPrimary: foreground

    readonly property color secondary: color5
    readonly property color secondaryContainer: Qt.rgba(color5.r, color5.g, color5.b, 0.2)

    readonly property color tertiary: color6
    readonly property color tertiaryContainer: Qt.rgba(color6.r, color6.g, color6.b, 0.2)

    readonly property color surface: background
    readonly property color surfaceDim: Qt.darker(background, 1.1)
    readonly property color surfaceBright: Qt.lighter(background, 1.3)
    readonly property color surfaceContainer: Qt.lighter(background, 1.15)
    readonly property color surfaceContainerLow: Qt.lighter(background, 1.08)
    readonly property color surfaceContainerHigh: Qt.lighter(background, 1.22)
    readonly property color surfaceContainerHighest: Qt.lighter(background, 1.3)
    readonly property color onSurface: foreground
    readonly property color onSurfaceVariant: color8

    readonly property color outline: color8
    readonly property color outlineVariant: Qt.rgba(color8.r, color8.g, color8.b, 0.5)

    readonly property color success: color2
    readonly property color onSuccess: background
    readonly property color warning: color3
    readonly property color onWarning: background
    readonly property color error: color1
    readonly property color onError: foreground
    readonly property color info: color4

    readonly property color inverseSurface: foreground
    readonly property color inverseOnSurface: background
    readonly property color inversePrimary: Qt.lighter(primary, 1.5)

    readonly property color scrim: Qt.rgba(0, 0, 0, 0.5)
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.3)

    function loadColors(text: string): void {
        try {
            const data = JSON.parse(text)
            if (data.special) {
                if (data.special.background) root.background = data.special.background
                if (data.special.foreground) root.foreground = data.special.foreground
                if (data.special.cursor) root.cursor = data.special.cursor
            }
            if (data.colors) {
                for (let i = 0; i <= 15; i++) {
                    const key = "color" + i
                    if (data.colors[key]) root[key] = data.colors[key]
                }
            }
        } catch (e) {}
    }

    Process {
        id: homeProc
        command: ["printenv", "HOME"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.homePath = data.trim()
                pywalFileView.path = root.pywalPath
                pywalFileView.reload()
            }
        }
    }

    FileView {
        id: pywalFileView
        path: ""
        watchChanges: true
        onLoaded: {
            const t = text()
            if (t && t.length > 0) root.loadColors(t)
        }
        onFileChanged: {
            const t = text()
            if (t && t.length > 0) root.loadColors(t)
        }
    }
}
