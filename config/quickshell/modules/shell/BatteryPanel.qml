// Battery menu: percentage, time left, power draw, health, screen brightness, power profile.
import QtQuick
import QtQuick.Layouts
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

    readonly property color level: !Battery.plugged && Battery.percent <= Config.batteryCritical ? Theme.m.error
                                  : !Battery.plugged && Battery.percent <= Config.batteryWarning ? Theme.m.warning
                                  : Battery.charging ? Theme.m.success : Theme.m.outline   // same rule as the bar: quiet unless something is up
    readonly property bool alert: Battery.charging || (!Battery.plugged && Battery.percent <= Config.batteryWarning)

    Column {
        width: parent.width
        spacing: 10
        Row {
            spacing: 12
            Txt { text: Battery.percent + "%"; font.pixelSize: 36; font.bold: true; color: alert ? level : Theme.m.fg }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Txt { text: Battery.charging ? "Charging" : Battery.plugged ? "Plugged in" : "On battery"; font.bold: true; font.pixelSize: Theme.font.small + 1 }
                Txt { text: Battery.timeLeft || (Battery.plugged ? "Fully charged" : ""); color: Theme.m.outline; font.pixelSize: Theme.font.small }
            }
        }
        // level bar
        RRect {
            width: parent.width; height: 8; radius: 3; antialiasing: true; color: Theme.m.containerHighest
            RRect { width: parent.width * Battery.percent / 100; height: parent.height; radius: 3; antialiasing: true; color: level }
        }
        Row {
            spacing: 16
            Txt { visible: Battery.watts > 0.1; text: Battery.watts.toFixed(1) + " W"; color: Theme.m.fgVariant; font.pixelSize: Theme.font.small }
            Txt { visible: Battery.health > 0; text: "Health " + Math.round(Battery.health) + "%"; color: Theme.m.fgVariant; font.pixelSize: Theme.font.small }
        }
        Section { visible: Brightness.available; text: "SCREEN" }
        RowLayout {
            visible: Brightness.available
            width: parent.width; spacing: 10
            Item {
                Layout.preferredWidth: 30; Layout.preferredHeight: 30
                Cut { anchors.fill: parent; cut: 7; color: Theme.m.containerHigh }
                MIcon { anchors.centerIn: parent; text: "light_mode"; filled: true; font.pixelSize: 18; color: Theme.m.fg }
            }
            Slider { Layout.fillWidth: true; value: Brightness.percent / 100; fill: Theme.m.fgVariant; onMoved: v => Brightness.set(v * 100) }
            Txt { text: Brightness.percent + "%"; color: Theme.m.fgVariant; font.pixelSize: Theme.font.small; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
        }
        Section { text: "POWER PROFILE" }
        // segmented control: icon on top, short label below (fits the width)
        Row {
            width: parent.width; spacing: 4
            Repeater {
                model: [["energy_savings_leaf", "saver", 0], ["balance", "balanced", 1], ["speed", "performance", 2]]
                // cut corner like every other control; the active one is tonal, accent on its icon
                Cut {
                    id: seg
                    required property var modelData
                    required property int index
                    readonly property bool on: Battery.profileName === (index === 0 ? "power saver" : modelData[1])
                    width: (parent.width - 8) / 3; height: 54
                    cut: 8
                    color: on ? Theme.m.selection : segArea.containsMouse ? Theme.m.containerHighest : Theme.m.containerHigh
                    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
                    Column {
                        anchors.centerIn: parent; spacing: 2
                        MIcon { anchors.horizontalCenter: parent.horizontalCenter; text: seg.modelData[0]; filled: seg.on; font.pixelSize: 20; color: seg.on ? Theme.m.primary : Theme.m.fg }
                        Txt { anchors.horizontalCenter: parent.horizontalCenter; text: seg.modelData[1]; font.pixelSize: 11; font.bold: seg.on; color: seg.on ? Theme.m.fgSelection : Theme.m.fgVariant }
                    }
                    MouseArea { id: segArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Battery.setProfile(seg.modelData[2]) }
                }
            }
        }
    }
}
