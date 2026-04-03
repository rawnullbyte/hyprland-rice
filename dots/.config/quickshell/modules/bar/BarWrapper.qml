import Quickshell
import Quickshell.Wayland
import QtQuick 6.10
import "../../config" as QsConfig

Scope {
    readonly property var config: QsConfig.Config



    // Bluetooth popup window
    Loader {
        id: bluetoothPopupLoader
        source: "components/BluetoothPopupWindow.qml"

        property var bluetoothPopup: item
    }

    // Network popup window
    Loader {
        id: networkPopupLoader
        source: "components/NetworkPopupWindow.qml"

        property var networkPopup: item
    }

    // Weather popup window
    Loader {
        id: weatherPopupLoader
        source: "components/WeatherPopupWindow.qml"

        property var weatherPopup: item
    }

    // Calendar popup window
    Loader {
        id: calendarPopupLoader
        source: "components/CalendarPopupWindow.qml"

        property var calendarPopup: item
    }

    // Settings popup window
    Loader {
        id: settingsPopupLoader
        source: "components/SettingsPopupWindow.qml"

        property var settingsPopup: item
    }

    // Tray menu popup window
    Loader {
        id: trayMenuPopupLoader
        source: "components/TrayMenuPopupWindow.qml"

        property var trayMenuPopup: item
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            property var modelData

            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: config.bar.height
            color: "transparent"

            // Bar content
            Loader {
                id: barLoader
                anchors.fill: parent
                source: "Bar.qml"

                 onStatusChanged: {
                     if (status === Loader.Ready) {
                         item.screen = Qt.binding(() => modelData)
                         item.barWindow = Qt.binding(() => window)
                         item.bluetoothPopup = Qt.binding(() => bluetoothPopupLoader.item)
                         item.networkPopup = Qt.binding(() => networkPopupLoader.item)
                         item.weatherPopup = Qt.binding(() => weatherPopupLoader.item)
                         item.calendarPopup = Qt.binding(() => calendarPopupLoader.item)
                          item.settingsPopup = Qt.binding(() => settingsPopupLoader.item)
                          item.trayMenuPopup = Qt.binding(() => trayMenuPopupLoader.item)
                     }
                 }
            }
        }
    }
}
