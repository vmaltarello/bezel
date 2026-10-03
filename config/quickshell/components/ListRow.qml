// Clickable menu row: icon (Material Symbol name in `symbol`, or a Nerd glyph in `icon`), text, note on the right.
import QtQuick
import qs.config

RRect {
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
    height: 38; radius: 8; antialiasing: true
    color: selected ? Theme.m.secondaryContainer : area.containsMouse ? Theme.m.containerHigh : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
    MIcon {
        id: ms
        x: 8; anchors.verticalCenter: parent.verticalCenter; width: 22
        visible: root.symbol !== ""
        text: root.symbol; filled: root.selected; font.pixelSize: 20
        color: root.selected ? Theme.m.fgSecondaryContainer : root.iconColor
    }
    Icon { id: ic; x: 10; anchors.verticalCenter: parent.verticalCenter; text: root.icon; color: root.iconColor; font.pixelSize: 16; visible: root.symbol === "" && text !== ""; width: 18 }
    Txt {
        x: ms.visible || ic.visible ? 38 : 12; anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - noteTxt.implicitWidth - 18; elide: Text.ElideRight
        text: root.text; color: root.selected ? Theme.m.fgSecondaryContainer : root.textColor; font.bold: root.selected
        font.pixelSize: Theme.font.small + 1
    }
    Txt {
        id: noteTxt
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        text: root.action ? "→" : root.note
        color: root.selected ? Theme.m.fgSecondaryContainer : Theme.m.outline; font.pixelSize: Theme.font.small
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
