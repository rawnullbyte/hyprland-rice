import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../../services" as QsServices

PanelWindow {
    id: popupWindow

    property bool shouldShow: false
    property int customRightMargin: 200

    readonly property var weather: QsServices.Weather
    readonly property var pywal: QsServices.Pywal

    readonly property color cSurface: pywal.background
    readonly property color cSurfaceContainer: Qt.lighter(pywal.background, 1.15)
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: Qt.rgba(cText.r, cText.g, cText.b, 0.6)
    readonly property color cBorder: Qt.rgba(cText.r, cText.g, cText.b, 0.08)

    screen: Quickshell.screens[0]
    anchors {
        top: true
        right: true
    }
    margins {
        right: customRightMargin
    }

    color: "transparent"
    implicitWidth: 300
    implicitHeight: contentColumn.implicitHeight + 32
    visible: shouldShow || container.opacity > 0

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // ==================== FOCUS & CLOSE LOGIC (same as other popups) ====================
    property bool hasFocused: false
    property bool isUnfocused: false

    function close() {
        shouldShow = false
        hasFocused = false
        isUnfocused = false
    }

    onShouldShowChanged: {
        if (!shouldShow) {
            hasFocused = false
            isUnfocused = false
        }
    }

    Timer {
        id: unfocusCloseTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (!container.activeFocus && popupWindow.shouldShow) {
                popupWindow.close()
            }
        }
    }

    FocusScope {
        id: container
        anchors.fill: parent
        scale: 0.94
        opacity: 0
        transformOrigin: Item.TopRight
        focus: true

        // Main focus logic - identical to menu, Bluetooth, Calendar, etc.
        onActiveFocusChanged: {
            if (activeFocus) {
                hasFocused = true
                isUnfocused = false
                unfocusCloseTimer.stop()
                return
            }

            // Lost focus
            if (popupWindow.shouldShow && opacity > 0.3) {
                isUnfocused = true
                unfocusCloseTimer.restart()
            }
        }

        Keys.onEscapePressed: popupWindow.close()

        Connections {
            target: popupWindow
            function onShouldShowChanged() {
                if (popupWindow.shouldShow) {
                    Qt.callLater(() => container.forceActiveFocus())
                }
            }
        }

        // Mouse hover fallback (kept and improved)
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
                if (!container.mouseInside && container.mouseHasEntered && popupWindow.shouldShow) {
                    popupWindow.shouldShow = false
                }
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

        // Animation
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

        // ==================== BACKGROUND & CONTENT ====================
        Rectangle {
            anchors.fill: parent
            radius: 16
            color: cSurface
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

                // Location
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "󰋑"
                        font.family: "Material Design Icons"
                        font.pixelSize: 10
                        color: cSubText
                    }

                    Text {
                        text: weather.ready ? weather.city : "Loading..."
                        font.family: "Inter"
                        font.pixelSize: 10
                        color: cSubText
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: weather.ready ? weather.icon : "󰖙"
                        font.family: "Material Design Icons"
                        font.pixelSize: 32
                        color: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.9)
                    }

                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: weather.ready ? `${weather.temp}°` : "--°"
                            font.family: "Inter"
                            font.pixelSize: 28
                            font.weight: Font.Light
                            color: cText
                        }

                        Text {
                            text: weather.ready ? weather.condition : "Loading..."
                            font.family: "Inter"
                            font.pixelSize: 12
                            color: cSubText
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: "Humidity"
                            font.family: "Inter"
                            font.pixelSize: 9
                            color: cSubText
                        }

                        Text {
                            text: weather.ready ? `${weather.humidity}%` : "--%"
                            font.family: "Inter"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: cText
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "󰖝"
                            font.family: "Material Design Icons"
                            font.pixelSize: 14
                            color: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.8)
                        }

                        Text {
                            text: weather.ready ? `${weather.windSpeed} km/h` : "-- km/h"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: cText
                        }

                        Text {
                            text: "Wind"
                            font.family: "Inter"
                            font.pixelSize: 9
                            color: cSubText
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "󰖐"
                            font.family: "Material Design Icons"
                            font.pixelSize: 14
                            color: Qt.rgba(pywal.warning.r, pywal.warning.g, pywal.warning.b, 0.8)
                        }

                        Text {
                            text: weather.ready ? `${Math.floor(Math.random() * 11)}` : "--"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: cText
                        }

                        Text {
                            text: "UV Index"
                            font.family: "Inter"
                            font.pixelSize: 9
                            color: cSubText
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "󰜗"
                            font.family: "Material Design Icons"
                            font.pixelSize: 14
                            color: Qt.rgba(pywal.secondary.r, pywal.secondary.g, pywal.secondary.b, 0.8)
                        }

                        Text {
                            text: "1013"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: cText
                        }

                        Text {
                            text: "Pressure"
                            font.family: "Inter"
                            font.pixelSize: 9
                            color: cSubText
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                Text {
                    text: "5-Day Forecast"
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: cSubText
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: ["Mon", "Tue", "Wed", "Thu", "Fri"]
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.03)

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: modelData
                                    font.family: "Inter"
                                    font.pixelSize: 9
                                    color: cSubText
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: ["󰖙", "󰖚", "󰖛", "󰖙", "󰖚"][index]
                                    font.family: "Material Design Icons"
                                    font.pixelSize: 16
                                    color: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.8)
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: ["24°", "22°", "19°", "21°", "23°"][index]
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: cText
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}