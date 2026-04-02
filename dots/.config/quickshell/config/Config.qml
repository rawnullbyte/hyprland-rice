pragma Singleton

import Quickshell

Singleton {
    readonly property BarConfig bar: BarConfig {}
    readonly property AppearanceConfig appearance: AppearanceConfig {}

    readonly property var controlCenter: ({
        width: 420,
        maxHeight: 860,
        padding: 20,
        spacing: 16,
        margin: 12,
        cornerRadius: 24
    })

    readonly property var sidebar: ({
        width: 380,
        maxHeight: 860,
        padding: 20,
        spacing: 16,
        margin: 12,
        cornerRadius: 24
    })

    readonly property var popups: ({
        width: 280,
        minHeight: 100,
        maxHeight: 400,
        hoverDelay: 300,
        margin: 6
    })
}
