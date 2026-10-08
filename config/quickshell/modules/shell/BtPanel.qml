// Bluetooth menu: on/off, paired devices (click = connect/disconnect), full management (bluetui).
import QtQuick
import Quickshell
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

    // BlueZ icon name -> Material Symbol
    function kind(d) {
        const i = d.icon ?? "";
        return /head|audio-card|speaker/.test(i) ? "headphones" : /phone/.test(i) ? "smartphone"
             : /keyboard/.test(i) ? "keyboard" : /mouse/.test(i) ? "mouse" : /gaming|joystick/.test(i) ? "stadia_controller" : "bluetooth";
    }

    Column {
        width: parent.width
        spacing: 2
        Header {
            title: "Bluetooth"
            subtitle: !Bt.enabled ? "off" : Bt.connected.length ? Bt.connected.length + " connected" : "no device connected"
            Switch { checked: Bt.enabled; onToggled: Bt.toggle() }
        }
        Section { text: "DEVICES"; visible: Bt.enabled }
        Repeater {
            model: Bt.enabled ? Bt.devices.filter(d => d.paired || d.connected) : []
            ListRow {
                required property var modelData
                symbol: kind(modelData)
                text: modelData.name
                selected: modelData.connected
                note: modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "connected") : "paired"
                onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
            }
        }
        Item { width: 1; height: 4 }
        ListRow { symbol: "settings"; text: "Manage devices"; action: true; onClicked: { Ui.close(); Quickshell.execDetached(["sh", "-c", Config.cmd.bluetooth]); } }
    }
}
