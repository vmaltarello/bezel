// Left vertical bar ("Developer"): launcher, workspaces, clock, tray, status, power.
// Status icons open the side menus. Groups sit in tonal containers with the cut top-left corner;
// the solid lavender accent marks only the active workspace and the open menu; the clock is tonal.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: bar
    anchors { left: true; top: true; bottom: true }
    implicitWidth: Theme.size.barWidth
    exclusiveZone: Theme.size.barWidth
    // background drawn as a Rectangle like the frame strips: a translucent window color is composed
    // differently by the software renderer and came out darker than the frame (visible seam)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    Rectangle { anchors.fill: parent; color: Theme.m.barGlass }

    // caffeine: blocks lock/suspend (hypridle respects the inhibitor)
    IdleInhibitor { window: bar; enabled: Caffeine.active }

    readonly property int unit: 40          // button size inside the groups

    // opens a side menu at the height of the clicked item
    function openAt(item, name) {
        Ui.anchorY = item.mapToItem(null, 0, item.height / 2).y;
        Ui.toggle(name);
    }

    // round icon button; tonal background while its menu is open
    component BarButton: Item {
        id: bb
        property string icon
        property bool filled: true
        property color iconColor: Theme.m.fg
        property color background: "transparent"
        property string panel: ""
        default property alias content: extra.data
        readonly property bool open: panel !== "" && Ui.panel === panel
        signal clicked()
        signal scrolled(int delta)
        width: bar.unit; height: bar.unit
        anchors.horizontalCenter: parent?.horizontalCenter
        Cut {
            anchors.fill: parent
            cut: 8
            color: bb.open ? Theme.m.primary : area.containsMouse ? Theme.m.containerHigh : bb.background
            Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
        }
        MIcon {
            anchors.centerIn: parent
            visible: bb.icon !== ""
            text: bb.icon; filled: bb.filled
            color: bb.open ? Theme.m.fgPrimary : bb.iconColor
        }
        Item { id: extra; anchors.fill: parent }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bb.panel ? bar.openAt(bb, bb.panel) : bb.clicked()
            // menus on hover (only for buttons that have one)
            onContainsMouseChanged: {
                if (!bb.panel) return;
                if (containsMouse) { Ui.hoverY = bb.mapToItem(null, 0, bb.height / 2).y; Ui.hoverIcon = bb.panel; }
                else if (Ui.hoverIcon === bb.panel) Ui.hoverIcon = "";
            }
            onWheel: wheel => bb.scrolled(wheel.angleDelta.y)
        }
    }

    // tonal container for a group of buttons
    component Group: Cut {
        default property alias items: col.data
        anchors.horizontalCenter: parent.horizontalCenter
        width: bar.unit; height: col.implicitHeight
        cut: 10
        color: Theme.m.barGroup
        Column { id: col; width: parent.width }
    }

    // ---------- top: launcher + workspaces ----------
    Column {
        anchors { top: parent.top; topMargin: 10; horizontalCenter: parent.horizontalCenter }
        spacing: 8

        // launcher
        BarButton {
            icon: "terminal"
            iconColor: Theme.m.primary
            background: Theme.m.primaryContainer
            onClicked: { Ui.launcherMode = "apps"; Ui.toggle("launcher"); }
        }

        // workspaces: up to 3 icons of the apps inside (one per app), "+n" for more, the number when empty.
        // Active: a solid lavender tile with the cut corner.
        Group {
            Item { width: 1; height: 4 }
            Repeater {
                model: Workspaces.count
                Item {
                    id: ws
                    required property int index
                    readonly property int wsId: index + 1
                    readonly property bool on: wsId === Workspaces.activeId
                    readonly property var wins: Workspaces.byId(wsId)?.toplevels.values ?? []
                    readonly property bool full: wins.length > 0
                    // one entry per app class, in window order
                    readonly property var apps: {
                        const seen = [];
                        for (const w of wins) { const c = Workspaces.appClass(w); if (c && !seen.includes(c)) seen.push(c); }
                        return seen;
                    }
                    readonly property int shown: Math.min(apps.length, 3)
                    readonly property int iconSize: shown > 1 ? 16 : 20
                    width: bar.unit
                    height: Math.max(34, shown * iconSize + (shown - 1) * 4 + 16)
                    Behavior on height { NumberAnimation { duration: Theme.anim.fast; easing.type: Easing.OutCubic } }

                    Cut {
                        id: tag
                        anchors { fill: parent; leftMargin: 4; rightMargin: 4; topMargin: 2; bottomMargin: 2 }
                        cut: 7
                        color: ws.on ? Theme.m.primary : wsArea.containsMouse ? Theme.m.containerHigh : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
                    }
                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Repeater {
                            model: ws.apps.slice(0, 3)
                            Item {
                                required property string modelData
                                required property int index
                                readonly property string src: Workspaces.icon(modelData)
                                readonly property bool more: index === 2 && ws.apps.length > 3
                                width: ws.iconSize; height: ws.iconSize
                                IconImage {
                                    anchors.fill: parent
                                    visible: parent.src !== "" && !parent.more
                                    source: parent.src
                                    opacity: ws.on || wsArea.containsMouse ? 1 : 0.7
                                }
                                // app without a known icon: first letter of its class
                                Txt {
                                    anchors.centerIn: parent
                                    visible: parent.src === "" && !parent.more
                                    text: parent.modelData.slice(0, 1).toUpperCase()
                                    font.pixelSize: 12; font.bold: true
                                    color: ws.on ? Theme.m.fgPrimary : Theme.m.fgVariant
                                }
                                Txt {
                                    anchors.centerIn: parent
                                    visible: parent.more
                                    text: "+" + (ws.apps.length - 2)
                                    font.pixelSize: 10; font.bold: true
                                    color: ws.on ? Theme.m.fgPrimary : Theme.m.fgVariant
                                }
                            }
                        }
                    }
                    // empty workspace: its number, muted (accent when active)
                    Txt {
                        anchors.centerIn: parent
                        visible: ws.apps.length === 0
                        text: ws.wsId
                        font.family: Theme.font.family
                        font.pixelSize: 13
                        font.weight: ws.on ? Font.Bold : Font.Medium
                        color: ws.on ? Theme.m.fgPrimary : wsArea.containsMouse || ws.full ? Theme.m.fgVariant : Theme.m.outline
                        Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
                    }
                    MouseArea {
                        id: wsArea
                        anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Workspaces.go(ws.wsId)
                    }
                }
            }
            Item { width: 1; height: 4 }
            WheelHandler {
                onWheel: event => Hyprland.dispatch(`hl.dsp.focus({ workspace = "${event.angleDelta.y > 0 ? "e-1" : "e+1"}" })`)
            }
        }
    }

    // ---------- center: clock ----------
    Cut {
        id: clock
        anchors.centerIn: parent
        width: bar.unit; height: clockCol.implicitHeight + 18
        cut: 10
        color: Theme.m.primaryContainer   // tonal: the only solid accent in the bar is the active workspace
        Column {
            id: clockCol
            anchors.centerIn: parent
            spacing: -3
            Repeater {
                model: Time.time.split(":")
                Txt {
                    required property string modelData
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData
                    font.family: Theme.font.heavy
                    font.pixelSize: 19; font.weight: Font.Black
                    color: Theme.m.primary
                }
            }
        }
    }

    // ---------- bottom: tray + status + power ----------
    Column {
        anchors { bottom: parent.bottom; bottomMargin: 10; horizontalCenter: parent.horizontalCenter }
        spacing: 8

        // background apps: in their own group like the rest of the bar, not loose icons
        Group {
            visible: SystemTray.items.values.length > 0
            Repeater {
                model: SystemTray.items.values
                Item {
                    id: trayItem
                    required property SystemTrayItem modelData
                    width: bar.unit; height: 34
                    Cut {
                        anchors { fill: parent; margins: 3 }
                        cut: 7
                        color: trayArea.containsMouse ? Theme.m.containerHigh : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
                    }
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 18
                        source: trayItem.modelData.icon
                    }
                    MouseArea {
                        id: trayArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            const it = trayItem.modelData;
                            if (mouse.button === Qt.LeftButton && !it.onlyMenu) it.activate();
                            else if (it.hasMenu) { const p = trayItem.mapToItem(null, trayItem.width + 12, 0); it.display(bar, p.x, p.y); }
                        }
                    }
                }
            }
        }

        Group {
            BarButton {
                icon: "coffee"; filled: Caffeine.active
                iconColor: Caffeine.active ? Theme.m.primary : Theme.m.fgVariant
                onClicked: Caffeine.toggle()
            }
            BarButton { visible: Dnd.active; icon: "notifications_off"; iconColor: Theme.m.warning; onClicked: Dnd.toggle() }
            BarButton {
                panel: "audio"
                icon: Audio.muted ? "volume_off" : Audio.headphones ? "headphones" : Audio.percent > 60 ? "volume_up" : Audio.percent > 0 ? "volume_down" : "volume_mute"
                iconColor: Audio.muted ? Theme.m.error : Theme.m.fg
                onScrolled: delta => Audio.step(delta > 0 ? 0.05 : -0.05)
            }
            BarButton {
                visible: Net.available
                panel: "net"
                icon: Net.ethernet ? "lan" : !Net.connected ? "wifi_off"
                    : Net.strength >= 75 ? "signal_wifi_4_bar" : Net.strength >= 50 ? "network_wifi_3_bar"
                    : Net.strength >= 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                iconColor: Net.connected ? Theme.m.fg : Theme.m.error
            }
            BarButton {
                visible: Bt.available
                panel: "bt"
                icon: !Bt.enabled ? "bluetooth_disabled" : Bt.connected.length ? "bluetooth_connected" : "bluetooth"
                filled: Bt.enabled
                iconColor: !Bt.enabled ? Theme.m.fgVariant : Theme.m.fg
            }
            // battery: vertical pill that fills up, percentage below
            BarButton {
                id: batBtn
                visible: Battery.present
                panel: "battery"
                height: 58
                readonly property color level: !Battery.plugged && Battery.percent <= Config.batteryCritical ? Theme.m.error
                                              : !Battery.plugged && Battery.percent <= Config.batteryWarning ? Theme.m.warning
                                              : Battery.charging ? Theme.m.success : Theme.m.outline   // quiet unless something is up
                RRect {
                    id: cell
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 9 }
                    width: 16; height: 24; radius: 3; antialiasing: true
                    color: Theme.m.outlineVariant
                    RRect {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: Math.max(6, parent.height * Battery.percent / 100)
                        radius: 2; antialiasing: true
                        color: batBtn.open ? Theme.m.fgPrimary : batBtn.level
                        Behavior on height { NumberAnimation { duration: Theme.anim.slow } }
                    }
                    MIcon {
                        anchors.centerIn: parent
                        visible: Battery.charging
                        text: "bolt"; filled: true; font.pixelSize: 14
                        color: Theme.m.surface
                    }
                }
                Txt {
                    anchors { horizontalCenter: parent.horizontalCenter; top: cell.bottom; topMargin: 3 }
                    text: Battery.percent
                    font.pixelSize: 11; font.bold: true
                    color: batBtn.open ? Theme.m.fgPrimary : Theme.m.fgVariant
                }
            }
        }

        BarButton {
            panel: "power"
            icon: "power_settings_new"
            iconColor: Theme.m.error
        }
    }
}
