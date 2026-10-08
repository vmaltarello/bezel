// Desktop widget column: today (time, date, month) · system · music · updates.
// Used by Desktop.qml (above wallpaper, below windows: visible on empty workspaces).
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Column {
    id: root
    width: 300
    spacing: 10

    readonly property int pad: 16

    // ISO week (Monday first, week 1 = the one with the first Thursday)
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
        return Math.ceil(((t - Date.UTC(t.getUTCFullYear(), 0, 1)) / 864e5 + 1) / 7);
    }
    function level(v, warn, crit, base) { return v >= crit ? Theme.c.red : v >= warn ? Theme.c.warm : base; }

    component Card: RRect {
        default property alias content: inner.data
        property int padding: root.pad
        width: root.width
        height: inner.implicitHeight + 2 * padding
        radius: Theme.size.cellRadius; antialiasing: true
        color: Theme.m.glass
        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.07)      // glass edge
        Column {
            id: inner
            x: parent.padding; y: parent.padding
            width: parent.width - 2 * parent.padding
            spacing: 10
        }
    }
    component Line: Item {
        property alias label: l.text
        property alias value: v.text
        property alias valueColor: v.color
        property alias note: n.text
        property alias noteColor: n.color
        width: parent.width; height: l.implicitHeight
        Row {
            spacing: 6
            Txt { id: l; color: Theme.c.muted; font.pixelSize: Theme.font.small }
            Txt { id: n; visible: text !== ""; color: Theme.c.dim; font.pixelSize: Theme.font.small }
        }
        Txt { id: v; anchors.right: parent.right; font.pixelSize: Theme.font.small }
    }

    // ---- today ----
    Card {
        Item {
            width: parent.width; height: clock.implicitHeight
            Txt { id: clock; text: Time.time; font.family: Theme.font.heavy; font.pixelSize: 62; font.weight: Font.Black }
            Txt {
                anchors { right: parent.right; baseline: clock.baseline }
                text: "Week " + root.isoWeek(Time.now); color: Theme.c.muted; font.pixelSize: 12
            }
        }
        Txt {
            text: Time.loc.toString(Time.now, "dddd d MMMM"); color: Theme.c.fg2; font.pixelSize: Theme.font.small + 1
            font.capitalization: Font.Capitalize
        }
        CalendarView { width: parent.width; height: 200 }
    }

    // ---- system ----
    Card {
        // one row per metric: name and value on the left, its own chart on the right
        component Metric: Item {
            id: m
            property string name
            property string value
            property string detail
            property color valueColor: Theme.m.fg
            property color detailColor: Theme.m.outline
            property alias values: sp.values
            property alias max: sp.max
            property alias color: sp.color
            width: parent.width; height: Math.max(44, txt.implicitHeight + 4)
            Column {
                id: txt
                width: 92
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Txt { text: m.name; color: Theme.m.outline; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.2 }
                Txt { text: m.value; color: m.valueColor; font.pixelSize: Theme.font.large; font.bold: true }
                Txt { text: m.detail; visible: text !== ""; color: m.detailColor; font.pixelSize: 11 }
            }
            RRect {
                anchors { left: txt.right; right: parent.right; top: parent.top; bottom: parent.bottom }
                radius: 6; antialiasing: true
                color: Qt.rgba(1, 1, 1, 0.03)
                Spark { id: sp; anchors { fill: parent; margins: 4 } }
            }
        }
        Metric {
            name: "CPU"
            value: System.cpu + "%"
            valueColor: root.level(System.cpu, Config.cpuWarning, Config.cpuCritical, Theme.m.fg)
            detail: System.temp ? System.temp + "°C" : ""
            detailColor: root.level(System.temp, Config.tempWarning, Config.tempCritical, Theme.m.outline)
            values: System.cpuHist; color: Theme.m.primary; max: Math.max(40, ...System.cpuHist)
        }
        Metric {
            name: "RAM"
            value: System.memUsed.toFixed(1) + "G"
            valueColor: root.level(System.mem, Config.memWarning, Config.memCritical, Theme.m.fg)
            detail: "of " + System.memTotal.toFixed(0) + "G" + (System.swapUsed >= 0.1 ? " · swap " + System.swapUsed.toFixed(1) : "")
            values: System.memHist; color: Theme.c.violet
        }
        // disks: only when nearly full
        Line {
            visible: System.diskRoot >= 90 || System.diskHome >= 90
            label: "disk"; valueColor: Theme.c.red
            value: [System.diskRoot >= 90 ? "/ " + System.diskRoot + "%" : "", System.diskHome >= 90 ? "/home " + System.diskHome + "%" : ""].filter(s => s).join(" · ") + " full"
        }
        Rectangle { visible: Battery.present; width: parent.width; height: 1; color: Theme.c.ink4 }
        Line {
            visible: Battery.present
            label: (Battery.charging ? "Charging " : "Battery ") + Battery.percent + "%"
            value: [Battery.timeLeft, Battery.watts >= 0.1 ? Battery.watts.toFixed(1) + " W" : ""].filter(s => s).join(" · ")
                   || (Battery.plugged ? "plugged in" : "")
            valueColor: Theme.c.fg2
        }
    }

    // ---- music: only when there is a track ----
    Card {
        visible: Media.active
        padding: 12
        Item {
            width: parent.width; height: 46
            RoundImage {
                id: cover
                width: 46; height: 46
                source: Media.art; background: "transparent"; cornerRadius: 0
                MIcon { anchors.centerIn: parent; visible: Media.art === ""; text: "music_note"; color: Theme.m.outline }
            }
            Column {
                anchors { left: cover.right; leftMargin: 12; right: controls.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                Txt { width: parent.width; text: Media.title; elide: Text.ElideRight; font.pixelSize: Theme.font.small + 1 }
                Txt { width: parent.width; text: Media.artist; elide: Text.ElideRight; color: Theme.c.muted; font.pixelSize: Theme.font.small }
            }
            Row {
                id: controls
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 12
                component Btn: MIcon {
                    signal clicked()
                    filled: true
                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
                }
                Btn { text: "skip_previous"; color: Theme.m.fgVariant; onClicked: Media.previous() }
                Btn { text: Media.playing ? "pause" : "play_arrow"; color: Theme.m.primary; onClicked: Media.toggle() }
                Btn { text: "skip_next"; color: Theme.m.fgVariant; onClicked: Media.next() }
            }
        }
    }

    // ---- updates: only when there are some ----
    Card {
        id: upd
        visible: Updates.count > 0 || Updates.upgrading
        padding: 12
        color: updArea.containsMouse ? Theme.m.container : Theme.m.glass
        Line {
            label: (Updates.upgrading ? "upgrading…" : Updates.count + (Updates.count === 1 ? " update" : " updates"))
            value: Updates.upgrading ? "" : "click to upgrade"
            valueColor: Theme.c.muted
        }
        MouseArea {
            id: updArea
            parent: upd; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: { Ui.close(); Updates.upgrade(); }
        }
    }
}
