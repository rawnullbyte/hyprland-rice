import QtQuick 6.10

QtObject {
    readonly property var workspaces: QtObject {
        property int count: 8
        property int workspaceSize: 18
        property int spacing: 6
        property int cornerRadius: 10
        property int indicatorSize: 4
        property int pillPadding: 8
    }

    readonly property int height: 36
    readonly property int padding: 4
    readonly property real backgroundOpacity: 0.0

    readonly property var islands: QtObject {
        property int borderRadius: 18
        property real glassOpacity: 0.92
        property real borderOpacity: 0.12
        property int spacing: 6
    }
}
