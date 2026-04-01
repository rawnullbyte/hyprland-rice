import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../services" as QsServices

// Weather indicator with popup
Item {
    id: root
    
     property var barWindow
    property var weatherPopup
    property var barRoot
    
    readonly property var pywal: QsServices.Pywal
    readonly property bool isHovered: mouseArea.containsMouse
    
    // Mock weather data
    readonly property string weatherIcon: "󰖙"
    readonly property int temperature: 22
    readonly property string condition: "Clear"
    readonly property int humidity: 45
    readonly property int wind: 12
    
    implicitWidth: weatherRow.implicitWidth
    implicitHeight: 20
    
    Row {
        id: weatherRow
        anchors.centerIn: parent
        spacing: 4
        
        Text {
            text: root.weatherIcon
            font.family: "Material Design Icons"
            font.pixelSize: 14
            color: isHovered ? pywal.primary : Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.9)
            anchors.verticalCenter: parent.verticalCenter
            
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        
        Text {
            text: root.temperature + "°"
            font.family: "Inter"
            font.pixelSize: 11
            font.weight: Font.Medium
            color: isHovered ? pywal.foreground : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.9)
            anchors.verticalCenter: parent.verticalCenter
            
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
            if (!weatherPopup) return
            
            if (weatherPopup.shouldShow) {
                weatherPopup.shouldShow = false
            } else {
                if (barRoot) barRoot.closeOtherPopups(weatherPopup)
                
                if (!barWindow || !barWindow.screen) return
                
                const pos = root.mapToItem(barWindow.contentItem, 0, 0)
                const centerX = pos.x + root.width / 2
                const screenWidth = barWindow.screen.width
                
                weatherPopup.customRightMargin = Math.round(screenWidth - centerX - 140)
                weatherPopup.shouldShow = true
            }
        }
    }
}
