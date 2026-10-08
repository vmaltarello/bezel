// Network menu: Wi-Fi on/off, networks found (click = connect), advanced settings (nmtui).
import QtQuick
import Quickshell
import Quickshell.Networking
import qs.config
import qs.services
import qs.components

Item {
    // side menu content (the animated container is SideHost.qml)
    readonly property int panelWidth: 310
    width: panelWidth - 32
    implicitHeight: childrenRect.height

    // title row: name on the left, optional switch on the right
    component Header: Item {
        property alias title: tt.text
        property alias subtitle: st.text
        default property alias trailing: slot.data
        width: parent.width; height: 44
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Txt { id: tt; font.family: Theme.font.heavy; font.weight: Font.Black; font.pixelSize: Theme.font.large + 1 }
            Txt { id: st; color: Theme.m.outline; font.pixelSize: Theme.font.small - 1; visible: text !== "" }
        }
        Item { id: slot; anchors { right: parent.right; verticalCenter: parent.verticalCenter } width: childrenRect.width; height: childrenRect.height }
    }
    component Section: Txt { color: Theme.m.outline; font.pixelSize: 11; font.letterSpacing: 1.4; font.bold: true; topPadding: 6; bottomPadding: 2 }

    // while the menu is open the Wi-Fi card scans
    Binding { target: Net.wifiDev; property: "scannerEnabled"; value: true; when: Net.wifiDev != null }

    function bars(s) { return s >= 0.75 ? "signal_wifi_4_bar" : s >= 0.5 ? "network_wifi_3_bar" : s >= 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar"; }

    Column {
        width: parent.width
        spacing: 2
        Header {
            title: "Wi-Fi"
            subtitle: Net.ethernet ? "wired" : Net.connected ? Net.name : "not connected"
            Switch { checked: Networking.wifiEnabled; onToggled: Networking.wifiEnabled = !Networking.wifiEnabled }
        }
        Section { text: "NETWORKS"; visible: Networking.wifiEnabled }
        Repeater {
            model: (Net.wifiDev?.networks.values ?? []).slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)).slice(0, 7)
            ListRow {
                required property var modelData
                symbol: bars(modelData.signalStrength)
                text: modelData.name
                selected: modelData.connected
                note: modelData.connected ? "connected" : modelData.known ? "saved" : modelData.security ? "secured" : "open"
                onClicked: {
                    if (modelData.connected) return;
                    if (modelData.known) modelData.connect();
                    else { Ui.close(); Quickshell.execDetached(["sh", "-c", Config.cmd.wifi]); }
                }
            }
        }
        Item { width: 1; height: 4 }
        ListRow { symbol: "settings"; text: "Network settings"; action: true; onClicked: { Ui.close(); Quickshell.execDetached(["sh", "-c", Config.cmd.wifi]); } }
    }
}
