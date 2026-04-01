//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import Quickshell.Services.Notifications
import QtQuick 6.10
import "services" as QsServices

ShellRoot {
    id: root

    readonly property var notifs: QsServices.Notifs
    readonly property var pywal: QsServices.Pywal
    readonly property var audio: QsServices.Audio
    readonly property var brightness: QsServices.Brightness

    NotificationServer {
        id: notificationServer

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true
            notifs.addNotification(notif)
        }
    }

    Loader {
        id: barLoader
        source: "modules/bar/BarWrapper.qml"
    }

    Loader {
        id: notificationPopupsLoader
        source: "modules/bar/components/NotificationPopups.qml"
    }
}
