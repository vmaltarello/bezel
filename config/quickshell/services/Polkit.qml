pragma Singleton
// Polkit agent: graphical apps that need admin rights ask the password here (replaces hyprpolkitagent).
// Only one agent per session: if another one is running, registration fails (isRegistered = false).
// Without an agent `pkexec` from a terminal still works (it asks in the terminal).
import QtQuick
import Quickshell
import Quickshell.Services.Polkit

Singleton {
    id: root
    readonly property bool registered: agent.isRegistered
    readonly property bool active: agent.isActive
    readonly property var flow: agent.flow

    PolkitAgent { id: agent }
}
