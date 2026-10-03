// Calendar: ‹ › change month (wheel too), click on the month = back to today, click on a day = select it.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.components

ColumnLayout {
    id: root
    property date shown: new Date()
    property date selected: new Date()
    spacing: 4

    function shift(n) { shown = new Date(shown.getFullYear(), shown.getMonth() + n, 1); }
    function same(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate(); }

    RowLayout {
        Layout.fillWidth: true
        MIcon { text: "chevron_left"; color: Theme.m.outline; font.pixelSize: 20; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.shift(-1) } }
        Txt {
            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
            text: Time.loc.toString(root.shown, "MMMM yyyy"); font.capitalization: Font.Capitalize; font.bold: true; color: Theme.c.blue
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.shown = new Date(); root.selected = new Date(); } }
        }
        MIcon { text: "chevron_right"; color: Theme.m.outline; font.pixelSize: 20; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.shift(1) } }
    }
    DayOfWeekRow {
        Layout.fillWidth: true
        locale: Time.loc
        delegate: Txt { required property string shortName; text: shortName.slice(0, 2); color: Theme.c.muted; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
    }
    MonthGrid {
        id: grid
        Layout.fillWidth: true; Layout.fillHeight: true
        month: root.shown.getMonth(); year: root.shown.getFullYear()
        locale: Time.loc
        spacing: 1
        delegate: RRect {
            id: day
            required property var model
            readonly property bool isSel: root.same(model.date, root.selected)
            radius: 6; antialiasing: true
            color: model.today ? Theme.c.blue : dayArea.containsMouse ? Theme.c.ink4 : "transparent"
            border.width: isSel && !model.today ? 1 : 0
            border.color: Theme.c.blue
            Txt {
                anchors.centerIn: parent; text: day.model.day; font.pixelSize: 13; font.bold: day.model.today || day.isSel
                color: day.model.today ? Theme.c.ink1 : day.model.month === grid.month ? Theme.c.fg : Theme.c.dim
            }
            MouseArea {
                id: dayArea
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { root.selected = day.model.date; if (day.model.month !== grid.month) root.shown = new Date(day.model.year, day.model.month, 1); }
            }
        }
    }
    WheelHandler { onWheel: event => root.shift(event.angleDelta.y > 0 ? -1 : 1) }
}
