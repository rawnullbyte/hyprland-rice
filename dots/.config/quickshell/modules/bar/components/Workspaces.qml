import Quickshell
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../config" as QsConfig
import "../../../services" as QsServices

Item {
    id: root
    
    property var screen
    
    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property var hypr: QsServices.Hypr
    readonly property int activeWsId: hypr.activeWsId
    readonly property var occupied: hypr.getOccupiedWorkspaces()
    
    readonly property int groupSize: 10
    readonly property int baseWs: {
        let ws = root.activeWsId
        if (ws < 1) ws = 1
        return Math.floor((ws - 1) / root.groupSize) * root.groupSize + 1
    }
    
    implicitWidth: layout.implicitWidth
    implicitHeight: config.bar.height - config.bar.padding * 2
    
    RowLayout {
        id: layout
        
        anchors.centerIn: parent
        spacing: root.config.bar.workspaces.spacing
        
        Repeater {
            id: workspaceRepeater
            model: root.config.bar.workspaces.count
            
            delegate: Loader {
                required property int index
                
                readonly property int wsId: root.baseWs + index
                
                source: "Workspace.qml"
                asynchronous: false
                
                onLoaded: {
                    item.workspaceId = wsId
                    item.isActive = Qt.binding(() => root.activeWsId === wsId)
                    item.isOccupied = Qt.binding(() => root.occupied[wsId] ?? false)
                    item.clicked.connect(function() {
                        if (root.hypr.activeWsId !== wsId) {
                            root.hypr.dispatch(`workspace ${wsId}`)
                        }
                    })
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) {
                root.hypr.dispatch("workspace -1")
            } else if (wheel.angleDelta.y < 0 || wheel.angleDelta.x < 0) {
                root.hypr.dispatch("workspace +1")
            }
            wheel.accepted = true
        }
    }
}
