import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Io
import "../../../services" as QsServices

PanelWindow {
    id: popupWindow

    property int customRightMargin: 0
    property bool shouldShow: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var pywal: QsServices.Pywal

    // Safe sorted & filtered devices (prevents null entries)
    readonly property var sortedDevices: {
        let list = []
        for (let key in Bluetooth.devices.values) {
            let dev = Bluetooth.devices.values[key]
            if (dev && dev.address && dev.name) {
                list.push(dev)
            }
        }
        return list.sort((a, b) => {
            if (a.connected !== b.connected) return b.connected - a.connected
            if (a.bonded !== b.bonded) return b.bonded - a.bonded
            return a.name.localeCompare(b.name)
        })
    }

    // Stable ListModel - prevents scroll reset
    ListModel {
        id: deviceModel
    }

    // Safe refresh timer
    Timer {
        id: modelRefreshTimer
        interval: 100
        repeat: false
        onTriggered: {
            deviceModel.clear()
            for (let dev of sortedDevices) {
                if (dev && dev.name) {
                    deviceModel.append({ modelData: dev })
                }
            }
        }
    }

    Connections {
        target: Bluetooth
        function onDefaultAdapterChanged() { modelRefreshTimer.restart() }
    }

    Connections {
        target: adapter
        ignoreUnknownSignals: true
        function onDevicesChanged() { modelRefreshTimer.restart() }
    }

    // ==================== MAIN onShouldShowChanged (only once) ====================
    onShouldShowChanged: {
        if (shouldShow) {
            modelRefreshTimer.restart()
            Qt.callLater(() => container.forceActiveFocus())
        } else {
            hasFocused = false
            isUnfocused = false
        }
    }

    // Colors
    readonly property color cSurface: pywal.background
    readonly property color cSurfaceContainer: Qt.lighter(pywal.background, 1.15)
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: Qt.rgba(cText.r, cText.g, cText.b, 0.6)
    readonly property color cBorder: Qt.rgba(cText.r, cText.g, cText.b, 0.08)
    readonly property color cHover: Qt.rgba(cText.r, cText.g, cText.b, 0.06)

    // Settings launcher
    Process {
        id: settingsProcess
        command: ["blueman-manager"]
        onStarted: popupWindow.shouldShow = false
    }

    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { right: customRightMargin }

    implicitWidth: 320
    implicitHeight: contentColumn.implicitHeight + 32
    color: "transparent"
    visible: shouldShow || container.opacity > 0

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // ==================== FOCUS & CLOSE LOGIC ====================
    property bool hasFocused: false
    property bool isUnfocused: false

    function close() {
        shouldShow = false
        hasFocused = false
        isUnfocused = false
    }

    Timer {
        id: unfocusCloseTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (!container.activeFocus && popupWindow.shouldShow) popupWindow.close()
        }
    }

    FocusScope {
        id: container
        anchors.fill: parent
        scale: 0.94
        opacity: 0
        transformOrigin: Item.TopRight
        focus: true

        onActiveFocusChanged: {
            if (activeFocus) {
                hasFocused = true
                isUnfocused = false
                unfocusCloseTimer.stop()
                return
            }
            if (popupWindow.shouldShow && opacity > 0.3) {
                isUnfocused = true
                unfocusCloseTimer.restart()
            }
        }

        Keys.onEscapePressed: popupWindow.close()

        property bool mouseHasEntered: false
        property bool mouseInside: hoverHandler.hovered

        Connections {
            target: popupWindow
            function onShouldShowChanged() {
                if (popupWindow.shouldShow) {
                    container.mouseHasEntered = false
                    mouseCloseTimer.stop()
                }
            }
        }

        Timer {
            id: mouseCloseTimer
            interval: 400
            onTriggered: {
                if (!container.mouseInside && container.mouseHasEntered && popupWindow.shouldShow)
                    popupWindow.shouldShow = false
            }
        }

        HoverHandler {
            id: hoverHandler
            onHoveredChanged: {
                if (hovered) {
                    container.mouseHasEntered = true
                    mouseCloseTimer.stop()
                } else if (container.mouseHasEntered && popupWindow.shouldShow) {
                    mouseCloseTimer.restart()
                }
            }
        }

        // Animations
        states: State {
            name: "visible"
            when: popupWindow.shouldShow
            PropertyChanges { target: container; opacity: 1; scale: 1.0 }
        }

        transitions: [
            Transition {
                to: "visible"
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; duration: 180; easing.type: Easing.OutQuad }
                    NumberAnimation { property: "scale"; duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                }
            },
            Transition {
                from: "visible"
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; duration: 120; easing.type: Easing.InQuad }
                    NumberAnimation { property: "scale"; to: 0.94; duration: 120 }
                }
            }
        ]

        Rectangle {
            id: backgroundRect
            anchors.fill: parent
            color: cSurface
            radius: 16
            border.width: 1
            border.color: cBorder

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.35)
                shadowBlur: 1.0
                shadowVerticalOffset: 6
            }

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 36; height: 36; radius: 12
                        color: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15)
                        Text {
                            anchors.centerIn: parent
                            text: "󰂯"
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: cPrimary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Bluetooth"
                            font.family: "Inter"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: cText
                        }
                        Text {
                            property var connected: sortedDevices.filter(d => d && d.connected)
                            text: connected.length > 0 ? connected[0].name : "No device connected"
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: cSubText
                        }
                    }

                    // Toggle Switch
                    Rectangle {
                        width: 44; height: 24; radius: 12
                        color: adapter?.enabled ? cPrimary : Qt.rgba(cText.r, cText.g, cText.b, 0.15)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            width: 18; height: 18; radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: adapter?.enabled ? parent.width - width - 3 : 3
                            color: "#ffffff"
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (adapter) adapter.enabled = !adapter.enabled
                        }
                    }
                }

                // Scan Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color: scanArea.containsMouse ? cHover : cSurfaceContainer

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: adapter?.discovering ? "󰑐" : "󰑓"
                            font.family: "Material Design Icons"
                            font.pixelSize: 16
                            color: adapter?.discovering ? cPrimary : cText

                            RotationAnimation on rotation {
                                running: adapter?.discovering ?? false
                                from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                            }
                        }
                        Text {
                            text: adapter?.discovering ? "Scanning..." : "Scan for devices"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: cText
                        }
                    }

                    MouseArea {
                        id: scanArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (adapter) {
                                adapter.discovering = !adapter.discovering
                                modelRefreshTimer.restart()
                            }
                        }
                    }
                }

                // Device List
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(deviceList.contentHeight + 8, 260)
                    radius: 12
                    color: cSurfaceContainer
                    clip: true

                    ListView {
                        id: deviceList
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2
                        model: deviceModel
                        clip: true

                        delegate: Rectangle {
                            id: deviceItem
                            width: deviceList.width
                            height: (modelData && modelData.name) ? 52 : 0
                            radius: 10
                            color: itemArea.containsMouse ? cHover : "transparent"
                            visible: modelData && modelData.name

                            required property var modelData
                            property bool isConnected: modelData ? modelData.connected : false

                            Behavior on color { ColorAnimation { duration: 80 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: {
                                        if (!modelData) return "󰂯"
                                        const icon = modelData.icon || ""
                                        if (icon.includes("audio")) return "󰋋"
                                        if (icon.includes("phone")) return "󰄜"
                                        if (icon.includes("computer")) return "󰌢"
                                        if (icon.includes("mouse")) return "󰍽"
                                        if (icon.includes("keyboard")) return "󰌌"
                                        return "󰂯"
                                    }
                                    font.family: "Material Design Icons"
                                    font.pixelSize: 18
                                    color: isConnected ? cPrimary : cText
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    RowLayout {
                                        spacing: 8
                                        Layout.fillWidth: true

                                        Text {
                                            text: modelData ? modelData.name : ""
                                            font.family: "Inter"
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                            color: cText
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        // Battery
                                        RowLayout {
                                            visible: modelData && modelData.batteryAvailable
                                            spacing: 3
                                            Layout.alignment: Qt.AlignVCenter

                                            Text {
                                                text: "󰁹"
                                                font.family: "Material Design Icons"
                                                font.pixelSize: 14
                                                color: cSubText
                                            }
                                            Text {
                                                text: modelData ? Math.round(modelData.battery * 100) + "%" : ""
                                                font.family: "Inter"
                                                font.pixelSize: 11
                                                color: cSubText
                                                font.weight: Font.Medium
                                            }
                                        }
                                    }

                                    Text {
                                        text: {
                                            if (!modelData) return ""
                                            if (modelData.state === BluetoothDeviceState.Connecting) return "Connecting..."
                                            if (isConnected) return "Connected"
                                            if (modelData.bonded) return "Paired"
                                            return "Available"
                                        }
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        color: isConnected ? cPrimary : cSubText
                                    }
                                }

                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: actionArea.containsMouse ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : "transparent"
                                    border.width: 1
                                    border.color: isConnected ? cPrimary : Qt.rgba(cText.r, cText.g, cText.b, 0.15)

                                    Text {
                                        anchors.centerIn: parent
                                        text: isConnected ? "󰌊" : "󰌘"
                                        font.family: "Material Design Icons"
                                        font.pixelSize: 14
                                        color: isConnected ? cPrimary : cSubText
                                    }

                                    MouseArea {
                                        id: actionArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData) modelData.connected = !isConnected
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: itemArea
                                anchors.fill: parent
                                hoverEnabled: true
                                z: -1
                            }
                        }
                    }

                    // Empty state
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: sortedDevices.length === 0
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰂲"
                            font.family: "Material Design Icons"
                            font.pixelSize: 32
                            color: Qt.rgba(cText.r, cText.g, cText.b, 0.2)
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: adapter?.enabled ? "No devices found" : "Bluetooth disabled"
                            font.family: "Inter"
                            font.pixelSize: 12
                            color: cSubText
                        }
                    }
                }

                // Settings Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color: settingsArea.containsMouse ? cHover : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰒓"
                            font.family: "Material Design Icons"
                            font.pixelSize: 14
                            color: cSubText
                        }
                        Text {
                            text: "Bluetooth Settings"
                            font.family: "Inter"
                            font.pixelSize: 12
                            color: cSubText
                        }
                    }

                    MouseArea {
                        id: settingsArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsProcess.running = true
                    }
                }
            }
        }
    }
}