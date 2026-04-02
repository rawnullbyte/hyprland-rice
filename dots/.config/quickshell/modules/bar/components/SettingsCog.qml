import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../services" as QsServices

Item {
    id: root

    property var barWindow
    property var settingsPopup
    property var barRoot

    readonly property var pywal: QsServices.Pywal
    readonly property bool isHovered: mouseArea.containsMouse

    implicitWidth: 28
    implicitHeight: 28

    Rectangle {
        anchors.centerIn: parent
        width: 24
        height: 24
        radius: 12
        color: isHovered ? Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.15) : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: "󰒓"
            font.family: "Material Design Icons"
            font.pixelSize: 14
            color: isHovered ? pywal.primary : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.7)

            // Subtle rotation on hover
            Behavior on color { ColorAnimation { duration: 150 } }
            rotation: isHovered ? 45 : 0
            Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {            
            if (!settingsPopup) return
            
            if (settingsPopup.shouldShow) {
                settingsPopup.shouldShow = false
            } else {
                if (barRoot) barRoot.closeOtherPopups(settingsPopup)
                
                if (!barWindow || !barWindow.screen) return
                
                const pos = root.mapToItem(barWindow.contentItem, 0, 0)
                const rightEdge = pos.x + root.width
                const screenWidth = barWindow.screen.width
                
                // Position popup below the bar
                settingsPopup.margins.right = Math.round(screenWidth - rightEdge - 8)
                settingsPopup.shouldShow = true
            }
        }
    }
}
