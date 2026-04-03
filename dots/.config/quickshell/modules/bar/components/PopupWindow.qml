import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../../../services" as QsServices

Item {
    id: root

    property bool shouldShow: false
    property var trayItem: null
    property var parentMenu: null
    property real anchorX: 0
    property real anchorY: 0

    readonly property var pywal: QsServices.Pywal
    readonly property color cSurface: pywal.background
    readonly property color cText: pywal.foreground
    readonly property color cSubText: Qt.rgba(cText.r, cText.g, cText.b, 0.6)
    readonly property color cBorder: Qt.rgba(cText.r, cText.g, cText.b, 0.08)
    readonly property color cHover: Qt.rgba(cText.r, cText.g, cText.b, 0.06)

    property real maxContentWidth: 250

    // Focus tracking
    property bool hasFocused: false
    property bool isUnfocused: false

    QsMenuOpener {
        id: menuOpener
    }

    property var menuStack: []
    property var currentMenu: null
    property int menuDepth: 0

    function close() {
        shouldShow = false
        hasFocused = false
        isUnfocused = false
        menuStack = []
        currentMenu = null
        menuDepth = 0
    }

    onShouldShowChanged: {
        if (!shouldShow) {
            hasFocused = false
            isUnfocused = false
            menuStack = []
            currentMenu = null
            menuDepth = 0
        }
    }

    Timer {
        id: unfocusCloseTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (!container.activeFocus && root.shouldShow) {
                root.close()
            }
        }
    }

    Timer {
        id: transitionTimer
        interval: 30
        repeat: false
        property var callback: null
        onTriggered: if (callback) callback()
    }

    Timer {
        id: layoutSettleTimer
        interval: 40
        repeat: false
        onTriggered: refreshMenuWidth()
    }

    function refreshMenuWidth() {
        if (!menuWindow) return

        var widest = 0
        for (var i = 0; i < menuRepeater.count; ++i) {
            var item = menuRepeater.itemAt(i)
            if (item && item.requiredWidth > widest)
                widest = item.requiredWidth
        }

        root.maxContentWidth = widest
        menuWindow.implicitWidth = menuWindow.calculateMenuWidth()
        menuWindow.updatePosition()
    }

    function loadMenu() {
        var menuToLoad = parentMenu ? parentMenu : (trayItem ? trayItem.menu : null)
        if (menuToLoad) {
            menuStack = [menuToLoad]
            currentMenu = menuToLoad
            menuDepth = 1
            menuOpener.menu = menuToLoad
            refreshMenuWidth()

            transitionTimer.stop()
            transitionTimer.interval = 40
            transitionTimer.callback = () => layoutSettleTimer.start()
            transitionTimer.start()
        }
    }

    function pushSubmenu(entry) {
        if (!entry || !entry.hasChildren) return

        menuStack.push(entry)
        currentMenu = entry
        menuDepth = menuStack.length
        menuOpener.menu = entry
        refreshMenuWidth()
    }

    function popSubmenu() {
        if (menuStack.length > 1) {
            menuStack.pop()
            currentMenu = menuStack[menuStack.length - 1]
            menuDepth = menuStack.length
            menuOpener.menu = currentMenu
            refreshMenuWidth()
        } else {
            root.close()
        }
    }

    // ==================== MENU WINDOW ====================
    PanelWindow {
        id: menuWindow

        screen: Quickshell.screens[0]
        anchors { top: true; right: true }
        margins {
            right: 0
            top: Math.max(0, anchorY - 6)
        }

        color: "transparent"
        implicitWidth: calculateMenuWidth()
        implicitHeight: Math.max(150, contentColumn.implicitHeight + 32)
        visible: root.shouldShow
        focusable: true

        WlrLayershell.keyboardFocus: root.shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        function calculateMenuWidth() {
            return Math.max(250, root.maxContentWidth + 34)
        }

        function updatePosition() {
            if (!screen) return
            const screenW = screen.width
            const menuW = width > 0 ? width : implicitWidth
            let ideal = screenW - anchorX - menuW / 2
            margins.right = Math.max(0, Math.min(ideal, screenW - menuW))
        }

        onImplicitWidthChanged: updatePosition()
        onWidthChanged: updatePosition()

        FocusScope {
            id: container
            anchors.fill: parent

            scale: 0.94
            opacity: 0
            transformOrigin: Item.TopRight
            focus: true

            // ==================== MAIN FOCUS LOGIC ====================
            onActiveFocusChanged: {
                if (activeFocus) {
                    hasFocused = true
                    isUnfocused = false
                    unfocusCloseTimer.stop()
                    return
                }

                // Menu lost focus
                if (root.shouldShow && opacity > 0.3) {
                    isUnfocused = true
                    unfocusCloseTimer.restart()
                }
            }

            Keys.onEscapePressed: {
                if (menuStack.length > 1)
                    popSubmenu()
                else
                    root.close()
            }

            Connections {
                target: menuWindow
                function onVisibleChanged() {
                    if (menuWindow.visible) {
                        root.loadMenu()
                        Qt.callLater(() => {
                            container.forceActiveFocus()
                        })
                    }
                }
            }

            states: State {
                name: "visible"
                when: root.shouldShow
                PropertyChanges { target: container; opacity: 1; scale: 1.0 }
            }

            transitions: [
                Transition {
                    to: "visible"
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; duration: 160; easing.type: Easing.OutQuad }
                        NumberAnimation { property: "scale"; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                    }
                },
                Transition {
                    from: "visible"
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; duration: 100; easing.type: Easing.InQuad }
                        NumberAnimation { property: "scale"; to: 0.94; duration: 100 }
                    }
                }
            ]

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

                    // Back button
                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 8
                        color: backButtonArea.containsMouse ? cHover : "transparent"
                        visible: root.menuDepth > 1

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            text: "< Back"
                            font.family: "Inter"
                            font.pixelSize: 13
                            color: cText
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: backButtonArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.popSubmenu()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: cBorder
                        visible: root.menuDepth > 1
                    }

                    // Menu items
                    ColumnLayout {
                        spacing: 2

                        Repeater {
                            id: menuRepeater
                            model: menuOpener.children.values

                            onModelChanged: Qt.callLater(root.refreshMenuWidth)

                            delegate: SubMenuItem {
                                menuEntry: modelData
                                rootItem: root
                            }
                        }
                    }
                }
            }
        }
    }

    // ==================== SUB MENU ITEM ====================
    component SubMenuItem: Rectangle {
        id: menuItem

        property var menuEntry: null
        property var rootItem: null
        property real requiredWidth: row.implicitWidth

        Layout.fillWidth: true
        height: menuEntry?.isSeparator ? 1 : 28
        radius: 8
        color: itemArea.containsMouse ? cHover : "transparent"
        visible: menuEntry != null

        RowLayout {
            id: row
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8
            visible: menuEntry && !menuEntry.isSeparator

            Image {
                width: 16
                height: 16
                source: menuEntry?.icon || ""
                visible: menuEntry?.icon && menuEntry.icon.length > 0
            }

            Text {
                Layout.fillWidth: false
                Layout.minimumWidth: implicitWidth
                Layout.preferredWidth: implicitWidth
                text: menuEntry?.text || ""
                font.family: "Inter"
                font.pixelSize: 13
                color: menuEntry?.enabled !== false ? cText : cSubText
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.NoWrap
            }

            Text {
                text: "▶"
                font.family: "Inter"
                font.pixelSize: 8
                color: cSubText
                visible: menuEntry?.hasChildren || false
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: 1
            width: parent.width - 24
            x: 12
            color: cBorder
            visible: menuEntry?.isSeparator || false
        }

        MouseArea {
            id: itemArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (!menuEntry) return
                if (menuEntry.hasChildren) {
                    rootItem.pushSubmenu(menuEntry)
                } else if (menuEntry.triggered) {
                    menuEntry.triggered()
                    rootItem.close()
                }
            }
        }
    }
}