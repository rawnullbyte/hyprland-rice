pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property list<Notif> notifications: []
    readonly property var activeNotifications: notifications.filter(n => !n.closed)
    readonly property int maxNotifications: 100

    readonly property var recentNotifications: notifications.filter(n => {
        const hours = (new Date().getTime() - n.timestamp.getTime()) / (1000 * 60 * 60)
        return hours < 24
    }).sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())

    readonly property var groupedNotifications: {
        const groups = {}
        for (const n of activeNotifications) {
            const key = n.appName || "Unknown"
            if (!groups[key]) groups[key] = []
            groups[key].push(n)
        }
        return groups
    }

    property bool dnd: false

    Timer {
        interval: 3600000
        repeat: true
        running: true
        onTriggered: {
            const cutoff = new Date().getTime() - (24 * 60 * 60 * 1000)
            root.notifications = root.notifications.filter(n => n.timestamp.getTime() > cutoff)
        }
    }

    function addNotification(notif: var): void {
        if (dnd && notif.urgency < 2) return
        const wrapper = notifComp.createObject(root, { notification: notif })
        root.notifications = [wrapper, ...root.notifications].slice(0, root.maxNotifications)
    }

    function toggleDnd(): void { dnd = !dnd }

    function clearAll(): void {
        notifications.forEach(n => n.close())
    }

    function deleteNotification(notif: var): void {
        if (notifications.includes(notif)) {
            root.notifications = notifications.filter(n => n !== notif)
            if (notif.notification) notif.notification.dismiss()
            notif.destroy()
        }
    }

    component Notif: QtObject {
        id: notifWrapper

        property var notification
        property date timestamp: new Date()
        property bool closed: false
        property bool hasAnimated: false

        property string id: ""
        property string summary: ""
        property string body: ""
        property string appName: ""
        property string appIcon: ""
        property string image: ""
        property int urgency: 0
        property list<var> actions: []

        readonly property string timeString: {
            const diff = new Date().getTime() - timestamp.getTime()
            const mins = Math.floor(diff / 60000)
            const hrs = Math.floor(mins / 60)
            const days = Math.floor(hrs / 24)
            if (days > 0) return days + "d ago"
            if (hrs > 0) return hrs + "h ago"
            if (mins > 0) return mins + "m ago"
            return "Just now"
        }

        readonly property Connections conn: Connections {
            target: notifWrapper.notification
            function onClosed() { notifWrapper.close() }
            function onSummaryChanged() { notifWrapper.summary = notifWrapper.notification.summary }
            function onBodyChanged() { notifWrapper.body = notifWrapper.notification.body }
            function onAppNameChanged() { notifWrapper.appName = notifWrapper.notification.appName }
            function onAppIconChanged() { notifWrapper.appIcon = notifWrapper.notification.appIcon }
            function onImageChanged() { notifWrapper.image = notifWrapper.notification.image }
            function onUrgencyChanged() { notifWrapper.urgency = notifWrapper.notification.urgency }
            function onActionsChanged() {
                notifWrapper.actions = notifWrapper.notification.actions.map(a => ({
                    identifier: a.identifier,
                    text: a.text,
                    invoke: () => a.invoke()
                }))
            }
        }

        function close(): void {
            if (closed) return
            closed = true
            if (notification) notification.dismiss()
        }

        function invokeAction(actionId: string): void {
            const a = actions.find(x => x.identifier === actionId)
            if (a && a.invoke) a.invoke()
        }

        Component.onCompleted: {
            if (!notification) return
            id = notification.id
            summary = notification.summary
            body = notification.body
            appName = notification.appName
            appIcon = notification.appIcon
            image = notification.image
            urgency = notification.urgency
            actions = notification.actions.map(a => ({
                identifier: a.identifier,
                text: a.text,
                invoke: () => a.invoke()
            }))
        }
    }

    Component { id: notifComp; Notif {} }
}
