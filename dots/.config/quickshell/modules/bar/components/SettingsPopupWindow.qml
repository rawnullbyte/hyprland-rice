import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import QtQuick.Controls 6.10
import Quickshell
import Quickshell.Wayland
import "../../../services" as QsServices

PanelWindow {
    id: popupWindow

    property bool shouldShow: false
    property int customRightMargin: 12

    readonly property var pywal: QsServices.Pywal
    readonly property var audio: QsServices.Audio
    readonly property var brightness: QsServices.Brightness
    readonly property var powerProfiles: QsServices.PowerProfiles
    readonly property var settingsControls: QsServices.SettingsControls

    readonly property color cSurface: pywal.background
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cBorder: Qt.rgba(cText.r, cText.g, cText.b, 0.08)
    readonly property color cSurfaceContainer: Qt.rgba(cText.r, cText.g, cText.b, 0.06)
    readonly property color cSurfaceHover: Qt.rgba(cText.r, cText.g, cText.b, 0.10)
    
    readonly property color cPrimaryActive: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.2)
    readonly property color cPrimaryBorder: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.4)
    readonly property color cPrimaryBorderHover: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.6)

    screen: Quickshell.screens[0]

    anchors {
        top: true
        right: true
    }

    margins {
        right: customRightMargin
    }

    color: "transparent"
    implicitWidth: 240
    implicitHeight: contentColumn.implicitHeight + 32
    visible: shouldShow || container.opacity > 0

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

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
            interval: 400
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
                } else {
                    closeTimer.start()
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
        }

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                text: "Quick Settings"
                font.family: "Inter"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: cPrimary
                Layout.bottomMargin: 4
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            Text {
                text: "Power Profile"
                font.family: "Inter"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Qt.rgba(cText.r, cText.g, cText.b, 0.5)
                Layout.topMargin: 4
            }

            // Optimized Power Profile Row with smooth animations
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    id: profileRepeater
                    model: popupWindow.powerProfiles.availableProfiles

                    Rectangle {
                        id: profileButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: 10
                        
                        property bool isActive: modelData === popupWindow.powerProfiles.activeProfile
                        property bool isHovered: false
                        
                        // Smooth color transitions
                        property color normalColor: isActive ? popupWindow.cPrimaryActive : cSurfaceContainer
                        property color hoverColor: cSurfaceHover
                        
                        color: isHovered ? hoverColor : normalColor
                        
                        Behavior on color {
                            ColorAnimation { 
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        border.width: 1
                        property color normalBorder: isActive ? popupWindow.cPrimaryBorder : "transparent"
                        property color hoverBorder: isActive ? popupWindow.cPrimaryBorderHover : Qt.rgba(cText.r, cText.g, cText.b, 0.15)
                        
                        border.color: isHovered ? hoverBorder : normalBorder
                        
                        Behavior on border.color {
                            ColorAnimation { 
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        // Click animation
                        property real normalScale: 1.0
                        property real pressedScale: 0.95
                        scale: normalScale
                        
                        Behavior on scale {
                            NumberAnimation { 
                                duration: 100
                                easing.type: Easing.OutBack
                                easing.overshoot: 0.5
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                id: iconText
                                text: {
                                    switch (modelData) {
                                        case "performance": return "󰓅"
                                        case "balanced": return "󰍷"
                                        case "power-saver": return "󰌪"
                                        default: return "󰍷"
                                    }
                                }
                                font.family: "Material Design Icons"
                                font.pixelSize: 14
                                color: profileButton.isActive ? popupWindow.cPrimary : popupWindow.cText
                                Layout.alignment: Qt.AlignHCenter
                                
                                Behavior on color {
                                    ColorAnimation { 
                                        duration: 100
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Text {
                                id: labelText
                                text: {
                                    switch (modelData) {
                                        case "performance": return "Perf"
                                        case "balanced": return "Bal"
                                        case "power-saver": return "Save"
                                        default: return modelData
                                    }
                                }
                                font.family: "Inter"
                                font.pixelSize: 8
                                font.weight: Font.Medium
                                color: profileButton.isActive ? popupWindow.cPrimary : Qt.rgba(popupWindow.cText.r, popupWindow.cText.g, popupWindow.cText.b, 0.6)
                                Layout.alignment: Qt.AlignHCenter
                                
                                Behavior on color {
                                    ColorAnimation { 
                                        duration: 100
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: profileMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            
                            onEntered: {
                                profileButton.isHovered = true
                            }
                            onExited: {
                                profileButton.isHovered = false
                            }
                            onClicked: {
                                profileButton.scale = profileButton.pressedScale
                                clickFeedbackTimer.start()
                                popupWindow.powerProfiles.setProfile(modelData)
                            }
                            
                            Timer {
                                id: clickFeedbackTimer
                                interval: 100
                                onTriggered: profileButton.scale = profileButton.normalScale
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.08)
                Layout.topMargin: 4
            }

            Text {
                text: "Controls"
                font.family: "Inter"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Qt.rgba(cText.r, cText.g, cText.b, 0.5)
                Layout.topMargin: 4
            }

            // DND Toggle - Integrated with SettingsControls service
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Dynamic DND icon that changes based on state
                Text {
                    id: dndIcon
                    text: settingsControls ? (settingsControls.dndEnabled ? "󰂚" : "󰂛") : "󰂛"
                    font.family: "Material Design Icons"
                    font.pixelSize: 14
                    color: settingsControls && settingsControls.dndEnabled ? popupWindow.cPrimary : popupWindow.cText
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                Text {
                    text: "Do Not Disturb"
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: popupWindow.cText
                    Layout.fillWidth: true
                }
                
                // Status label
                Text {
                    text: settingsControls ? (settingsControls.dndEnabled ? "On" : "Off") : "Off"
                    font.family: "Inter"
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: settingsControls && settingsControls.dndEnabled ? popupWindow.cPrimary : Qt.rgba(popupWindow.cText.r, popupWindow.cText.g, popupWindow.cText.b, 0.5)
                    visible: settingsControls && settingsControls.isAvailable
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                Rectangle {
                    id: dndToggle
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 20
                    radius: 10
                    color: dndMouseArea.containsMouse ? 
                           (settingsControls && settingsControls.dndEnabled ? Qt.rgba(popupWindow.cPrimary.r, popupWindow.cPrimary.g, popupWindow.cPrimary.b, 0.5) : Qt.rgba(1, 1, 1, 0.15)) :
                           (settingsControls && settingsControls.dndEnabled ? popupWindow.cPrimary : Qt.rgba(1, 1, 1, 0.1))

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                        x: (settingsControls && settingsControls.dndEnabled) ? parent.width - 18 : 2

                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: dndMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            if (settingsControls && settingsControls.toggleDND) {
                                settingsControls.toggleDND()
                            } else {
                                console.warn("SettingsControls not available or toggleDND not found")
                            }
                        }
                    }
                }
            }

            // Audio Mute Toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: popupWindow.audio.muted ? "󰖁" : "󰕾"
                    font.family: "Material Design Icons"
                    font.pixelSize: 14
                    color: popupWindow.audio.muted ? popupWindow.cPrimary : popupWindow.cText
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                Text {
                    text: "Mute Audio"
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: popupWindow.cText
                    Layout.fillWidth: true
                }
                
                // Status label
                Text {
                    text: popupWindow.audio.muted ? "Muted" : "On"
                    font.family: "Inter"
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: popupWindow.audio.muted ? popupWindow.cPrimary : Qt.rgba(popupWindow.cText.r, popupWindow.cText.g, popupWindow.cText.b, 0.5)
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                Rectangle {
                    id: muteToggle
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 20
                    radius: 10
                    color: muteMouseArea.containsMouse ? 
                           (popupWindow.audio.muted ? Qt.rgba(popupWindow.cPrimary.r, popupWindow.cPrimary.g, popupWindow.cPrimary.b, 0.5) : Qt.rgba(1, 1, 1, 0.15)) :
                           (popupWindow.audio.muted ? popupWindow.cPrimary : Qt.rgba(1, 1, 1, 0.1))

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                        x: popupWindow.audio.muted ? parent.width - 18 : 2

                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: muteMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: popupWindow.audio.toggleMute()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // Volume Section
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: popupWindow.audio.muted ? "󰖁" : (popupWindow.audio.percentage >= 70 ? "󰕾" : (popupWindow.audio.percentage >= 30 ? "󰖀" : "󰕿"))
                    font.family: "Material Design Icons"
                    font.pixelSize: 14
                    color: popupWindow.cText
                }

                Text {
                    text: "Volume"
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: popupWindow.cText
                    Layout.fillWidth: true
                }

                Text {
                    text: popupWindow.audio.percentage + "%"
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Qt.rgba(popupWindow.cText.r, popupWindow.cText.g, popupWindow.cText.b, 0.6)
                }
            }

            Slider {
                id: volumeSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                from: 0
                to: 100
                value: popupWindow.audio.percentage
                stepSize: 1
                onMoved: popupWindow.audio.setVolume(value / 100)

                background: Rectangle {
                    x: volumeSlider.leftPadding
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: volumeSlider.availableWidth
                    height: 4
                    radius: 2
                    color: Qt.rgba(popupWindow.cText.r, popupWindow.cText.g, popupWindow.cText.b, 0.1)

                    Rectangle {
                        width: volumeSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: popupWindow.cPrimary
                    }
                }

                handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: 14
                    height: 14
                    radius: 7
                    color: "#ffffff"

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.25)
                        shadowBlur: 0.5
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // Brightness Section
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰃠"
                    font.family: "Material Design Icons"
                    font.pixelSize: 14
                    color: popupWindow.cText
                }

                Text {
                    text: "Brightness"
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: popupWindow.cText
                    Layout.fillWidth: true
                }

                Text {
                    text: popupWindow.brightness.percentage + "%"
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Qt.rgba(popupWindow.cText.r, popupWindow.cText.g, popupWindow.cText.b, 0.6)
                }
            }

            Slider {
                id: brightnessSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                from: 0
                to: 100
                value: popupWindow.brightness.percentage
                stepSize: 1
                onMoved: popupWindow.brightness.setBrightness(value / 100)

                background: Rectangle {
                    x: brightnessSlider.leftPadding
                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                    width: brightnessSlider.availableWidth
                    height: 4
                    radius: 2
                    color: Qt.rgba(popupWindow.cText.r, popupWindow.cText.g, popupWindow.cText.b, 0.1)

                    Rectangle {
                        width: brightnessSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: popupWindow.cPrimary
                    }
                }

                handle: Rectangle {
                    x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                    width: 14
                    height: 14
                    radius: 7
                    color: "#ffffff"

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.25)
                        shadowBlur: 0.5
                    }
                }
            }
        }
    }
}