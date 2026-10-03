// Session menu: lock, suspend, log out, reboot, shut down.
// Log out / reboot / shut down go through hyprshutdown (closes apps cleanly).
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Item {
    // side menu content (the animated container is SideHost.qml)
    readonly property int panelWidth: 230
    width: panelWidth - 32
    implicitHeight: childrenRect.height
    Column {
        width: parent.width
        spacing: 2
        Repeater {
            model: [
                ["lock", "Lock", ["loginctl", "lock-session"]],
                ["bedtime", "Suspend", ["systemctl", "suspend"]],
                ["logout", "Log out", ["hyprshutdown", "-t", "Logging out..."]],
                ["restart_alt", "Reboot", ["hyprshutdown", "-t", "Rebooting...", "-p", "systemctl reboot"]],
                ["power_settings_new", "Shut down", ["hyprshutdown", "-t", "Shutting down...", "-p", "systemctl poweroff"]]
            ]
            ListRow {
                required property var modelData
                required property int index
                symbol: modelData[0]
                iconColor: index === 4 ? Theme.m.error : Theme.m.fgVariant
                text: modelData[1]
                textColor: index === 4 ? Theme.m.error : Theme.m.fg
                onClicked: { Ui.close(); Quickshell.execDetached(modelData[2]); }
            }
        }
    }
}
