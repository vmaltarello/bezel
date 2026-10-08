// Audio menu: volume, brightness, microphone, output device (click = use it), full mixer.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.config
import qs.services
import qs.components

Item {
    // side menu content (the animated container is SideHost.qml)
    readonly property int panelWidth: 320
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

    // icon + slider + value, all on one line
    component Level: RowLayout {
        property alias symbol: ic.text
        property alias iconColor: ic.color
        property alias value: sl.value
        property alias fill: sl.fill
        property string label
        signal moved(real v)
        signal iconClicked()
        width: parent.width; spacing: 10
        Item {
            Layout.preferredWidth: 30; Layout.preferredHeight: 30
            Cut { anchors.fill: parent; cut: 7; color: icArea.containsMouse ? Theme.m.containerHighest : Theme.m.containerHigh }
            MIcon { id: ic; anchors.centerIn: parent; filled: true; font.pixelSize: 18 }
            MouseArea { id: icArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.parent.iconClicked() }
        }
        Slider { id: sl; Layout.fillWidth: true; onMoved: v => parent.moved(v) }
        Txt { text: parent.label; color: Theme.m.fgVariant; font.pixelSize: Theme.font.small; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
    }

    Column {
        width: parent.width
        spacing: 8
        Header { title: "Sound"; subtitle: Audio.sink?.description ?? "" }
        Level {
            symbol: Audio.muted ? "volume_off" : Audio.headphones ? "headphones" : Audio.percent > 60 ? "volume_up" : "volume_down"
            iconColor: Audio.muted ? Theme.m.error : Theme.m.fg
            value: Audio.muted ? 0 : Math.min(1, Audio.volume)
            label: Audio.muted ? "Muted" : Audio.percent + "%"
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
        }
        Level {
            visible: Brightness.available
            symbol: "light_mode"; iconColor: Theme.m.fg
            value: Brightness.percent / 100; fill: Theme.m.fgVariant
            label: Brightness.percent + "%"
            onMoved: v => Brightness.set(v * 100)
        }
        RowLayout {
            width: parent.width; spacing: 10
            Item {
                Layout.preferredWidth: 30; Layout.preferredHeight: 30
                Cut { anchors.fill: parent; cut: 7; color: Theme.m.containerHigh }
                MIcon { anchors.centerIn: parent; text: Audio.micMuted ? "mic_off" : "mic"; filled: true; font.pixelSize: 18; color: Audio.micMuted ? Theme.m.error : Theme.m.fg }
            }
            Txt { text: Audio.micMuted ? "Microphone muted" : "Microphone on"; Layout.fillWidth: true; font.pixelSize: Theme.font.small + 1 }
            Switch { checked: !Audio.micMuted; onToggled: Audio.toggleMicMute() }
        }
        Section { text: "OUTPUT" }
        Column {
            width: parent.width; spacing: 2
            Repeater {
                model: Pipewire.nodes.values.filter(n => n.isSink && n.audio && !n.isStream)
                ListRow {
                    required property var modelData
                    symbol: /bluez/i.test(modelData.name) ? "headphones" : /hdmi/i.test(modelData.name) ? "tv" : "speaker"
                    text: modelData.description || modelData.nickname || modelData.name
                    selected: modelData === Audio.sink
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }
        ListRow { symbol: "tune"; text: "Full mixer"; action: true; onClicked: { Ui.close(); Quickshell.execDetached(["sh", "-c", Config.cmd.mixer]); } }
    }
}
