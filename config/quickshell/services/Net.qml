pragma Singleton
// Network (NetworkManager). Named Net to avoid clashing with the Network type of Quickshell.Networking.
// Wi-Fi or wired, network name and signal.
import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    readonly property var devices: Networking.devices.values
    readonly property var wifiDev: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDev: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: wifiDev?.networks.values.find(n => n.connected) ?? null

    // false when NetworkManager isn't running (network managed by something else): the bar hides the button
    readonly property bool available: devices.length > 0
    readonly property bool ethernet: wiredDev != null
    readonly property bool connected: ethernet || wifi != null
    readonly property string name: ethernet ? (wiredDev.name ?? "wired") : (wifi?.name ?? "")
    readonly property int strength: Math.round((wifi?.signalStrength ?? 0) * 100)
    readonly property bool wifiEnabled: Networking.wifiEnabled
}
