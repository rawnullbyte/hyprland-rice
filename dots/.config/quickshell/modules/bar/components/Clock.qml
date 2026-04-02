import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../services" as QsServices

Item {
    id: root
    
     property var barWindow
    property var calendarPopup
    property var barRoot
    
    implicitWidth: clockRow.implicitWidth + 12
    implicitHeight: clockRow.implicitHeight + 8
    
    readonly property var time: QsServices.Time
    readonly property var pywal: QsServices.Pywal
    readonly property bool isHovered: mouseArea.containsMouse
    
    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 8
        
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            
            Text {
                text: time.hours
                color: isHovered ? pywal.primary : pywal.foreground
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "Inter"
                font.letterSpacing: 0.3
                
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            
            Text {
                id: colonSeparator
                text: ":"
                color: pywal.primary
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "Inter"
                
                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }
            
            Text {
                text: time.minutes
                color: isHovered ? pywal.primary : pywal.foreground
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "Inter"
                font.letterSpacing: 0.3
                
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
        
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: time.dateShort
            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, isHovered ? 0.9 : 0.6)
            font.pixelSize: 10
            font.weight: Font.Medium
            font.family: "Inter"
            
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
         onClicked: {
            if (!calendarPopup) return
            
            if (calendarPopup.shouldShow) {
                calendarPopup.shouldShow = false
            } else {
                if (barRoot) barRoot.closeOtherPopups(calendarPopup)
                
                if (!barWindow || !barWindow.screen) return
                
                const pos = root.mapToItem(barWindow.contentItem, 0, 0)
                const centerX = pos.x + root.width / 2
                const screenWidth = barWindow.screen.width
                
                calendarPopup.customRightMargin = Math.round(screenWidth - centerX - 140)
                calendarPopup.shouldShow = true
            }
        }
    }
}
