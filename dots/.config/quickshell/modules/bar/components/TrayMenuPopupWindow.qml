import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../../services" as QsServices

PanelWindow {
    id: popupWindow

    property var menuHandle: null
    property bool shouldShow: false

    readonly property var pywal: QsServices.Pywal
    readonly property color cSurface: pywal.background
    readonly property color cSurfaceContainer: Qt.lighter(pywal.background, 1.15)
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: Qt.rgba(cText.r, cText.g, cText.b, 0.6)
    readonly property color cBorder: Qt.rgba(cText.r, cText.g, cText.b, 0.08)
    readonly property color cHover: Qt.rgba(cText.r, cText.g, cText.b, 0.06)

    screen: Quickshell.screens[0]

    anchors {
        top: true
        right: true
    }

    margins {
        right: 0
    }

    implicitWidth: Math.max(220, menuColumn.implicitWidth + 32)
    implicitHeight: Math.min(500, menuColumn.implicitHeight + 32)
    color: "transparent"
    visible: shouldShow || container.opacity > 0

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    QsMenuOpener {
        id: menuOpener
        menu: popupWindow.menuHandle
    }

    FocusScope {
        id: container
        anchors.fill: parent
        scale: 0.94
        opacity: 0
        transformOrigin: Item.TopRight
        focus: true

        Keys.onEscapePressed: popupWindow.shouldShow = false

        property bool mouseHasEntered: false
        property bool mouseInside: hoverHandler.hovered

        Connections {
            target: popupWindow
            function onShouldShowChanged() {
                if (popupWindow.shouldShow) {
                    container.mouseHasEntered = false
                    closeTimer.stop()
                }
            }
        }

        Timer {
            id: closeTimer
            interval: 300
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
                    closeTimer.stop()
                } else if (container.mouseHasEntered && popupWindow.shouldShow) {
                    closeTimer.restart()
                }
            }
        }

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
            border.color: cBorder
            border.width: 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.35)
                shadowBlur: 1.0
                shadowVerticalOffset: 6
            }

            ColumnLayout {
                id: menuColumn
                anchors.fill: parent
                anchors.margins: 8
                spacing: 1

                Repeater {
                    model: menuOpener.children

                    delegate: MouseArea {
                        id: menuItemArea
                        Layout.fillWidth: true
                        Layout.preferredHeight: modelData.isSeparator ? 8 : 32
                        hoverEnabled: modelData.isSeparator ? false : true
                        cursorShape: modelData.isSeparator ? Qt.ArrowCursor : Qt.PointingHandCursor

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 8
                            color: {
                                if (modelData.isSeparator) return "transparent"
                                if (menuItemArea.containsMouse) return cHover
                                return "transparent"
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            height: 1
                            color: cBorder
                            visible: modelData.isSeparator
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            visible: !modelData.isSeparator
                            spacing: 8

                            Item {
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (modelData.buttonType === QsMenuButtonType.CheckBox) {
                                            return modelData.checkState === Qt.Checked ? "󰄴" : "󰄱"
                                        }
                                        if (modelData.buttonType === QsMenuButtonType.RadioButton) {
                                            return modelData.checkState === Qt.Checked ? "󰐼" : "󰐽"
                                        }
                                        return ""
                                    }
                                    color: modelData.enabled ? cPrimary : cSubText
                                    font.family: "Material Design Icons"
                                    font.pixelSize: 14
                                    visible: modelData.buttonType !== QsMenuButtonType.None
                                }
                            }

                            Text {
                                text: modelData.text || ""
                                Layout.fillWidth: true
                                color: modelData.enabled ? cText : cSubText
                                font.family: "Inter"
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                        }

                        onClicked: {
                            if (!modelData.isSeparator && modelData.enabled) {
                                modelData.triggered()
                                popupWindow.shouldShow = false
                            }
                        }
                    }
                }
            }
        }
    }
}
