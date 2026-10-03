pragma Singleton
// Notifications: Quickshell is the notification server (replaces mako). No history:
// each notification shows up, goes away by itself after a few seconds (or on click), and that's it.
// Do not disturb (Dnd) hides all of them except critical ones.
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    // on-screen notifications, newest on top
    readonly property var list: server.trackedNotifications.values.slice().reverse().slice(0, 4)
    readonly property bool loaded: list.length > 0 || hiding.running
    onListChanged: if (list.length === 0) hiding.restart()
    Timer { id: hiding; interval: 400 }

    // time on screen: what the app asks for, otherwise 5 s; critical ones stay until dismissed
    function timeout(n) {
        if (n.urgency === NotificationUrgency.Critical) return 0;
        return n.expireTimeout > 0 ? Math.min(n.expireTimeout, 15000) : 5000;
    }

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: n => {
            if (Dnd.active && n.urgency !== NotificationUrgency.Critical) return;   // not tracked = dropped
            n.tracked = true;
        }
    }
}
