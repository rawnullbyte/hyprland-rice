import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import qs.services
import "../../../components"

Item {
    id: root
    implicitWidth: hasPlayer ? 180 : 100
    implicitHeight: 30

    readonly property var player: Players.active
    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: player?.isPlaying ?? false
    property real progressPercent: 0

    Timer {
        id: progressTimer
        interval: 500
        running: hasPlayer && isPlaying
        repeat: true
        onTriggered: {
            if (player && player.length > 0) {
                root.progressPercent = player.position / player.length
            }
        }
    }

    Item {
        id: mainContent
        anchors.fill: parent
        anchors.margins: 4
        visible: hasPlayer

        Rectangle {
            id: albumArt
            width: 18; height: 18; radius: 3
            color: Qt.rgba(Pywal.background.r, Pywal.background.g, Pywal.background.b, 0.5)
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectFit
            }
        }

        Column {
            id: textCol
            anchors.left: albumArt.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: progressBarBg.top
            spacing: -2

            // ==================== TITLE MARQUEE ====================
            Item {
                id: titleContainer
                width: parent.width
                height: 12
                clip: true

                readonly property real textGap: 80
                property real scrollX: 0

                readonly property bool canScroll: titleMeasure.contentWidth > width

                Connections {
                    target: titleMeasure
                    function onTextChanged() {
                        titleAnim.stop()
                        titleContainer.scrollX = 0
                        if (titleContainer.canScroll && root.isPlaying) {
                            titleAnim.restart()
                        }
                    }
                }

                NumberAnimation {
                    id: titleAnim
                    target: titleContainer
                    property: "scrollX"
                    from: 0
                    to: titleMeasure.contentWidth + titleContainer.textGap
                    duration: Math.max(2000, (titleMeasure.contentWidth + titleContainer.textGap) * 40)
                    loops: Animation.Infinite
                    running: titleContainer.canScroll && root.isPlaying
                }

                Text {
                    id: titleMeasure
                    text: root.player?.trackTitle || "Unknown"
                    font.family: "Inter"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    visible: false
                }

                Component {
                    id: titleComp
                    Text {
                        text: titleMeasure.text
                        font: titleMeasure.font
                        color: Pywal.foreground
                    }
                }

                Loader {
                    sourceComponent: titleComp
                    x: -titleContainer.scrollX
                    anchors.verticalCenter: parent.verticalCenter
                }

                Loader {
                    sourceComponent: titleComp
                    x: (titleMeasure.contentWidth + titleContainer.textGap) - titleContainer.scrollX
                    anchors.verticalCenter: parent.verticalCenter
                    visible: titleContainer.canScroll
                }
            }

            // ==================== AUTHOR MARQUEE ====================
            Item {
                id: authorContainer
                width: parent.width
                height: 10
                clip: true

                readonly property real textGap: 80
                property real scrollX: 0

                readonly property bool canScroll: authorMeasure.contentWidth > width

                Connections {
                    target: authorMeasure
                    function onTextChanged() {
                        authorAnim.stop()
                        authorContainer.scrollX = 0
                        if (authorContainer.canScroll && root.isPlaying) {
                            authorAnim.restart()
                        }
                    }
                }

                NumberAnimation {
                    id: authorAnim
                    target: authorContainer
                    property: "scrollX"
                    from: 0
                    to: authorMeasure.contentWidth + authorContainer.textGap
                    duration: Math.max(1800, (authorMeasure.contentWidth + authorContainer.textGap) * 50)
                    loops: Animation.Infinite
                    running: authorContainer.canScroll && root.isPlaying
                }

                Text {
                    id: authorMeasure
                    text: root.player?.trackArtist || "Unknown Artist"
                    font.family: "Inter"
                    font.pixelSize: 8
                    visible: false
                }

                Component {
                    id: authorComp
                    Text {
                        text: authorMeasure.text
                        font: authorMeasure.font
                        color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.6)
                    }
                }

                Loader {
                    sourceComponent: authorComp
                    x: -authorContainer.scrollX
                    anchors.verticalCenter: parent.verticalCenter
                }

                Loader {
                    sourceComponent: authorComp
                    x: (authorMeasure.contentWidth + authorContainer.textGap) - authorContainer.scrollX
                    anchors.verticalCenter: parent.verticalCenter
                    visible: authorContainer.canScroll
                }
            }
        }

        // Progress Bar
        Rectangle {
            id: progressBarBg
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            radius: 1
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.1)

            Rectangle {
                height: parent.height
                width: Math.max(0, Math.min(parent.width, parent.width * root.progressPercent))
                radius: 1
                color: Pywal.primary

                Behavior on width {
                    NumberAnimation { duration: 550; easing.type: Easing.Linear }
                }
            }
        }
    }

    // Placeholder when no player
    Row {
        anchors.centerIn: parent
        spacing: 4
        visible: !hasPlayer

        Text {
            text: "󰎇"
            font.family: "Material Design Icons"
            font.pixelSize: 12
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.4)
        }
        Text {
            text: "No media"
            font.family: "Inter"
            font.pixelSize: 10
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.4)
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) root.player?.previous()
            else if (mouse.button === Qt.MiddleButton) root.player?.togglePlaying()
            else if (mouse.button === Qt.RightButton) root.player?.next()
        }
    }
}