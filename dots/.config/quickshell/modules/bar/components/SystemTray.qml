import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../services" as QsServices

RowLayout {
    id: root
    spacing: 4

    property var barWindow
    property var trayMenuPopup

    readonly property var pywal: QsServices.Pywal
    readonly property bool hasItems: SystemTray.items.length > 0

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: trayItem
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: 6
            color: {
                if (mouseArea.containsMouse && pywal.foreground) {
                    return Qt.rgba(
                        pywal.foreground.r,
                        pywal.foreground.g,
                        pywal.foreground.b,
                        0.08
                    )
                }
                return "transparent"
            }

            Behavior on color {
                ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            IconImage {
                id: iconImage
                anchors.centerIn: parent
                width: 16
                height: 16
                source: modelData.icon
                mipmap: true
                asynchronous: true

                opacity: modelData.status === "Passive" ? 0.5 : 1.0
            }

            Rectangle {
                anchors.centerIn: parent
                width: 4
                height: 4
                radius: 2
                color: "#658676"
                visible: modelData.status === "NeedsAttention"

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                SequentialAnimation on opacity {
                    running: modelData.status === "NeedsAttention"
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 600 }
                    NumberAnimation { to: 1.0; duration: 600 }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                hoverEnabled: true

                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                        trayMenuPopup.menuHandle = modelData.menu
                        trayMenuPopup.shouldShow = true
                    } else if (mouse.button === Qt.LeftButton) {
                        trayMenuPopup.shouldShow = false
                        modelData.activate()
                    } else if (mouse.button === Qt.MiddleButton) {
                        trayMenuPopup.shouldShow = false
                        modelData.secondaryActivate()
                    }
                }

                onWheel: (wheel) => {
                    if (wheel.angleDelta.y !== 0) {
                        modelData.scroll(wheel.angleDelta.y / 120, false)
                    }
                    if (wheel.angleDelta.x !== 0) {
                        modelData.scroll(wheel.angleDelta.x / 120, true)
                    }
                }
            }

            ToolTip {
                id: toolTip
                visible: mouseArea.containsMouse && (modelData.tooltipTitle || modelData.tooltipDescription)
                delay: 500
                timeout: 3000
                text: {
                    let parts = []
                    if (modelData.tooltipTitle) parts.push(modelData.tooltipTitle)
                    if (modelData.tooltipDescription) parts.push(modelData.tooltipDescription)
                    return parts.join("\n")
                }
                font.pixelSize: 12
                padding: 6
                leftPadding: 10
                rightPadding: 10
                topPadding: 6
                bottomPadding: 6
            }
        }
    }
}
