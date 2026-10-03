// On/off switch: tight corners, amber when on.
import QtQuick
import qs.config

RRect {
    id: root
    property bool checked: false
    signal toggled()
    width: 38; height: 22; radius: 6; antialiasing: true
    color: checked ? Theme.m.primary : Theme.m.containerHighest
    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
    RRect {
        width: 16; height: 16; radius: 4; antialiasing: true; y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? Theme.m.fgPrimary : Theme.m.outline
        Behavior on x { NumberAnimation { duration: Theme.anim.fast; easing.type: Easing.OutCubic } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled() }
}
