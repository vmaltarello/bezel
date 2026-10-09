// Clickable menu row: icon (Material Symbol name in `symbol`, or a Nerd glyph in `icon`), text, note on the right.
import QtQuick
import qs.config

Cut {
    id: root
    property string symbol
    property string icon
    property color iconColor: Theme.m.fgVariant
    property string text
    property string note
    property bool selected: false
    property bool action: false          // "open something" row: muted text and a trailing arrow
    property color textColor: action ? Theme.m.fgVariant : Theme.m.fg
    signal clicked()
    width: parent ? parent.width : 200
    height: 38; cut: 8
    // selected: tonal background, the accent only on the tick and the icon
    color: selected ? Theme.m.selection : area.containsMouse ? Theme.m.containerHigh : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
    Rectangle {
        visible: root.selected
        x: 0; width: 3; height: 16; anchors.verticalCenter: parent.verticalCenter
        color: Theme.m.primary
    }
    MIcon {
        id: ms
        x: 8; anchors.verticalCenter: parent.verticalCenter; width: 22
        visible: root.symbol !== ""
        text: root.symbol; filled: root.selected; font.pixelSize: 20
        color: root.selected ? Theme.m.primary : root.iconColor
    }
    Icon { id: ic; x: 10; anchors.verticalCenter: parent.verticalCenter; text: root.icon; color: root.selected ? Theme.m.primary : root.iconColor; font.pixelSize: 16; visible: root.symbol === "" && text !== ""; width: 18 }
    Txt {
        x: ms.visible || ic.visible ? 38 : 12; anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - noteTxt.implicitWidth - 18; elide: Text.ElideRight
        text: root.text; color: root.selected ? Theme.m.fgSelection : root.textColor; font.bold: root.selected
        font.pixelSize: Theme.font.small + 1
    }
    Txt {
        id: noteTxt
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        text: root.action ? "→" : root.note
        color: root.selected ? Theme.m.fgPrimaryContainer : Theme.m.outline; font.pixelSize: Theme.font.small
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
