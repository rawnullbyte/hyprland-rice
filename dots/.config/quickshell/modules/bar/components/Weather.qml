import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 2.15
import Quickshell
import "../../../services" as QsServices

Item {
    id: root
    
    property var barWindow: null
    property var weatherPopup: null
    property var barRoot: null
    
    readonly property var weather: QsServices.Weather
    readonly property var pywal: QsServices.Pywal
    readonly property bool isHovered: mouseArea.containsMouse
    
    readonly property string displayTemp: weather.ready ? `${weather.temp}°` : "--"

    implicitWidth: mainLayout.implicitWidth
    implicitHeight: 24
    
    Row {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 6
        
        Text {
            id: iconText
            text: weather.ready ? weather.icon : "󰖙"
            font.family: "Material Design Icons"
            font.pixelSize: 15
            color: isHovered ? pywal.primary : Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.8)
            anchors.verticalCenter: parent.verticalCenter
            
            opacity: weather.ready ? 1.0 : 0.4
            Behavior on opacity { NumberAnimation { duration: 600 } }
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        
        Text {
            text: root.displayTemp
            font.family: "Inter"
            font.pixelSize: 11
            font.weight: Font.Medium
            color: isHovered ? pywal.foreground : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.9)
            anchors.verticalCenter: parent.verticalCenter
            
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            if (!weatherPopup) return
            
            if (weatherPopup.shouldShow) {
                weatherPopup.shouldShow = false
            } else {
                if (barRoot && barRoot.closeOtherPopups) {
                    barRoot.closeOtherPopups(weatherPopup)
                }
                
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