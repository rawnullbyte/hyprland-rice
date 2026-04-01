import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../../services" as QsServices

// Calendar popup - matching Bluetooth/WiFi style
PanelWindow {
    id: popupWindow
    
    property bool shouldShow: false
    property int customRightMargin: 200
    
    readonly property var pywal: QsServices.Pywal
    readonly property var time: QsServices.Time
    
    // Colors matching Bluetooth/WiFi style
    readonly property color cSurface: pywal.background
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cBorder: Qt.rgba(cText.r, cText.g, cText.b, 0.08)
    
    // Current date info
    readonly property var currentDate: new Date()
    readonly property int currentDay: currentDate.getDate()
    readonly property int currentMonth: currentDate.getMonth()
    readonly property int currentYear: currentDate.getFullYear()
    
    // Month names
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June",
                                        "July", "August", "September", "October", "November", "December"]
    
    // Get first day of month (0 = Sunday)
    readonly property int firstDayOfMonth: new Date(currentYear, currentMonth, 1).getDay()
    // Get days in current month
    readonly property int daysInMonth: new Date(currentYear, currentMonth + 1, 0).getDate()
    
    screen: Quickshell.screens[0]
    
    anchors {
        top: true
        right: true
    }
    
    margins {
        top: 36
        right: customRightMargin
    }
    
    color: "transparent"
    implicitWidth: 280
    implicitHeight: contentColumn.implicitHeight + 32
    visible: shouldShow || container.opacity > 0
    
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
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
        
        // Animation
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
        
        // Background
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
            anchors.margins: 16
            spacing: 10
            
            // Header - Month/Year
            Text {
                text: monthNames[currentMonth] + " " + currentYear
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: Font.Medium
                color: cText
                Layout.alignment: Qt.AlignHCenter
            }
            
            // Day names header
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                
                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                    
                    Text {
                        text: modelData
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        color: Qt.rgba(cText.r, cText.g, cText.b, 0.5)
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
            
            // Calendar grid
            Grid {
                Layout.fillWidth: true
                columns: 7
                spacing: 2
                
                // Empty cells for days before month starts
                Repeater {
                    model: firstDayOfMonth
                    
                    Rectangle {
                        width: 32
                        height: 28
                        color: "transparent"
                    }
                }
                
                // Days of the month
                Repeater {
                    model: daysInMonth
                    
                    Rectangle {
                        width: 32
                        height: 28
                        radius: 14
                        color: isToday ? cPrimary : (hoverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                        
                        property bool isToday: (index + 1) === currentDay
                        
                        Text {
                            anchors.centerIn: parent
                            text: index + 1
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.weight: isToday ? Font.Bold : Font.Normal
                            color: isToday ? "#ffffff" : cText
                        }
                        
                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                        
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }
            }
            
            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }
            
            // Current time
            Text {
                text: time.hours + ":" + time.minutes
                font.family: "Inter"
                font.pixelSize: 22
                font.weight: Font.Light
                color: cPrimary
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
