// Battery menu: percentage, time left, power draw, health, power profile.
import QtQuick
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
            Txt { id: tt; font.bold: true; font.pixelSize: Theme.font.normal }
            Txt { id: st; color: Theme.m.outline; font.pixelSize: Theme.font.small - 1; visible: text !== "" }
        }
        Item { id: slot; anchors { right: parent.right; verticalCenter: parent.verticalCenter } width: childrenRect.width; height: childrenRect.height }
    }
    component Section: Txt { color: Theme.m.outline; font.pixelSize: 11; font.letterSpacing: 1.4; font.bold: true; topPadding: 6; bottomPadding: 2 }

    readonly property color level: !Battery.plugged && Battery.percent <= Config.batteryCritical ? Theme.m.error
                                  : !Battery.plugged && Battery.percent <= Config.batteryWarning ? Theme.m.warning : Theme.m.tertiary

    Column {
        width: parent.width
        spacing: 10
        Row {
            spacing: 12
            Txt { text: Battery.percent + "%"; font.pixelSize: 36; font.bold: true; color: level }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Txt { text: Battery.charging ? "Charging" : Battery.plugged ? "Plugged in" : "On battery"; font.bold: true; font.pixelSize: Theme.font.small + 1 }
                Txt { text: Battery.timeLeft || (Battery.plugged ? "fully charged" : ""); color: Theme.m.outline; font.pixelSize: Theme.font.small }
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
            Txt { visible: Battery.health > 0; text: "health " + Math.round(Battery.health) + "%"; color: Theme.m.fgVariant; font.pixelSize: Theme.font.small }
        }
        Section { text: "POWER PROFILE" }
        // segmented control: icon on top, short label below (fits the width)
        Row {
            width: parent.width; spacing: 4
            Repeater {
                model: [["energy_savings_leaf", "saver", 0], ["balance", "balanced", 1], ["speed", "performance", 2]]
                RRect {
                    id: seg
                    required property var modelData
                    required property int index
                    readonly property bool on: Battery.profileName === (index === 0 ? "power saver" : modelData[1])
                    width: (parent.width - 8) / 3; height: 54
                    radius: on ? 8 : 6; antialiasing: true
                    topLeftRadius: index === 0 ? 10 : radius; bottomLeftRadius: index === 0 ? 10 : radius
                    topRightRadius: index === 2 ? 10 : radius; bottomRightRadius: index === 2 ? 10 : radius
                    color: on ? Theme.m.primary : segArea.containsMouse ? Theme.m.containerHighest : Theme.m.containerHigh
                    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
                    Column {
                        anchors.centerIn: parent; spacing: 2
                        MIcon { anchors.horizontalCenter: parent.horizontalCenter; text: seg.modelData[0]; filled: seg.on; font.pixelSize: 20; color: seg.on ? Theme.m.fgPrimary : Theme.m.fg }
                        Txt { anchors.horizontalCenter: parent.horizontalCenter; text: seg.modelData[1]; font.pixelSize: 11; font.bold: seg.on; color: seg.on ? Theme.m.fgPrimary : Theme.m.fgVariant }
                    }
                    MouseArea { id: segArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Battery.setProfile(seg.modelData[2]) }
                }
            }
        }
    }
}
