import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import qs.services
import "../../../components"

// Compact Music Widget
Item {
    id: root
    
    property var barWindow
    property var mediaPopup
    
    implicitWidth: hasPlayer ? 180 : 100
    implicitHeight: 24
    
    readonly property var player: Players.active
    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property real progress: player?.position ?? 0
    readonly property real duration: player?.length ?? 1
    readonly property real progressPercent: duration > 0 ? progress / duration : 0
    
    // No media placeholder
    Row {
        anchors.centerIn: parent
        spacing: 4
        visible: !hasPlayer
        
        Text {
            text: "󰎇"
            font.family: "Material Design Icons"
            font.pixelSize: 12
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.4)
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: "No media"
            font.family: "Inter"
            font.pixelSize: 10
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.4)
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    
    // Main content when playing
    Item {
        id: mainContent
        anchors.fill: parent
        visible: hasPlayer
        
        // Album art - smaller
        Rectangle {
            id: albumArt
            width: 18
            height: 18
            radius: 3
            color: Qt.rgba(Pywal.background.r, Pywal.background.g, Pywal.background.b, 0.5)
            border.width: 1
            border.color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.2)
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            
            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectFit
                clip: true
                visible: root.player?.trackArtUrl !== undefined && root.player?.trackArtUrl !== ""
            }
            
            Text {
                anchors.centerIn: parent
                text: "󰎇"
                font.family: "Material Design Icons"
                font.pixelSize: 9
                color: Qt.rgba(Pywal.primary.r, Pywal.primary.g, Pywal.primary.b, 0.6)
                visible: root.player?.trackArtUrl === undefined || root.player?.trackArtUrl === ""
                
                RotationAnimation on rotation {
                    running: root.isPlaying
                    from: 0
                    to: 360
                    duration: 3000
                    loops: Animation.Infinite
                }
            }
        }
        
         // Texts
        Column {
            anchors.left: albumArt.right
            anchors.leftMargin: 6
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: -2
            
            Text {
                text: root.player?.trackTitle ?? "Unknown"
                font.family: "Inter"
                font.pixelSize: 9
                font.weight: Font.Medium
                color: Pywal.foreground
                elide: Text.ElideRight
                width: parent.width
            }
            
             Text {
                text: root.player?.trackArtist ?? ""
                font.family: "Inter"
                font.pixelSize: 8
                color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.6)
                elide: Text.ElideRight
                width: parent.width
                visible: text.length > 0
                topPadding: -3
            }
        }
        
        // Progress bar at very bottom of media player
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            radius: 1
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.1)
            visible: hasPlayer
            
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * root.progressPercent
                radius: 1
                color: Qt.rgba(Pywal.primary.r, Pywal.primary.g, Pywal.primary.b, 0.8)
                
                Behavior on width {
                    NumberAnimation { duration: 300 }
                }
            }
        }
    }
    
    // Mouse area
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton && root.player?.canGoPrevious) {
                root.player.previous()
            } else if (mouse.button === Qt.MiddleButton && root.player?.canTogglePlaying) {
                root.player.togglePlaying()
            } else if (mouse.button === Qt.RightButton && root.player?.canGoNext) {
                root.player.next()
            }
        }
    }
}
