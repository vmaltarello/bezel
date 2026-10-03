pragma Singleton
// Bluetooth (BlueZ). Named Bt to avoid clashing with the Quickshell.Bluetooth module.
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter != null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var devices: adapter?.devices.values ?? []
    readonly property var connected: devices.filter(d => d.connected)

    function toggle() { if (adapter) adapter.enabled = !adapter.enabled; }
}
