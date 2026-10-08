// On/off switch with the cut corner, orange when on.
import QtQuick
import qs.config

Cut {
    id: root
    property bool checked: false
    signal toggled()
    width: 40; height: 22; cut: 7
    color: checked ? Theme.m.primary : Theme.m.containerHighest
    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
    Rectangle {
        width: 16; height: 16; antialiasing: true; y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? Theme.m.fgPrimary : Theme.m.outline
        Behavior on x { NumberAnimation { duration: Theme.anim.fast; easing.type: Easing.OutCubic } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled() }
}
