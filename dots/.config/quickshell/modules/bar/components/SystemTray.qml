import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root
    property var barWindow: null
    property var trayMenuPopup: null
    property var trayItemPopup: null
    property var barRoot: null

    readonly property var allTrayItems: SystemTray.items.values
    readonly property int trayCount: allTrayItems ? allTrayItems.length : 0

    QsMenuOpener {
        id: menuOpener
    }

    implicitWidth: trayRow.width
    implicitHeight: 24
    visible: trayCount > 0
    opacity: trayCount > 0 ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.trayCount

            delegate: Item {
                id: delegateItem
                width: 22
                height: 22

                property var trayItem: {
                    if (index >= root.allTrayItems.length) return null
                    return root.allTrayItems[index]
                }

                property string iconSource: {
                    if (!trayItem) return ""
                    let icon = trayItem.icon
                    if (typeof icon === 'string') {
                        if (icon === "") return ""
                        if (icon.startsWith("image://icon/")) return icon
                        if (icon.includes("?path=")) {
                            const split = icon.split("?path=")
                            if (split.length !== 2) return icon
                            const name = split[0]
                            const path = split[1]
                            let fileName = name.substring(name.lastIndexOf("/") + 1)
                            return `file://${path}/${fileName}`
                        }
                        if (icon.startsWith("/") && !icon.startsWith("file://"))
                            return `file://${icon}`
                        return icon
                    }
                    return ""
                }

                Rectangle {
                    width: 22
                    height: 22
                    radius: 6
                    color: trayArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

                    Image {
                        id: trayIcon
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: delegateItem.iconSource
                        asynchronous: true
                        smooth: true
                        mipmap: true
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !trayIcon.visible && trayItem
                        text: trayItem?.id ? trayItem.id.charAt(0).toUpperCase() : "?"
                        font.pixelSize: 10
                        color: "#ffffff"
                    }
                }

                MouseArea {
                    id: trayArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(mouse) {
                        if (!trayItem) return

                        if (mouse.button === Qt.LeftButton) {
                            if (trayItem.activate) {
                                trayItem.activate()
                            }
                        } 
                        else if (mouse.button === Qt.RightButton) {

                            // Force close any currently open menu first
                            if (trayItemPopup) {
                                trayItemPopup.shouldShow = false
                                if (trayItemPopup.close) {
                                    trayItemPopup.close()
                                }
                            }

                            // Close other popups via barRoot (safety)
                            if (barRoot && barRoot.closeOtherPopups) {
                                barRoot.closeOtherPopups(trayItemPopup)
                            }

                            // Small delay to ensure the old menu is fully gone before opening new one
                            Qt.callLater(function() {
                                menuOpener.menu = trayItem.menu

                                if (!barWindow || !barWindow.screen) return

                                const pos = root.mapToItem(barWindow.contentItem, delegateItem.x, delegateItem.y)
                                const centerX = pos.x + delegateItem.width / 2

                                if (trayItemPopup) {
                                    trayItemPopup.trayItem = trayItem
                                    trayItemPopup.anchorX = centerX
                                    trayItemPopup.anchorY = pos.y
                                    trayItemPopup.shouldShow = true
                                }
                            })
                        }
                    }
                }
            }
        }
    }
}