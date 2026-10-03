// Horizontal slider (volume, brightness). value 0..1; drag, click or wheel.
// Developer look: flat track with a filled part and a thin cursor-like handle.
import QtQuick
import qs.config

Item {
    id: root
    property real value: 0
    property color fill: Theme.m.primary
    signal moved(real v)

    implicitHeight: 22

    RRect {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 8; radius: 3; antialiasing: true
        color: Theme.m.containerHighest
        RRect {
            width: Math.max(4, parent.width * root.value); height: parent.height; radius: 3; antialiasing: true
            color: root.fill
            Behavior on width { NumberAnimation { duration: area.pressed ? 0 : Theme.anim.fast } }
        }
    }
    // handle: a vertical bar, like a text cursor
    RRect {
        x: Math.max(0, Math.min(track.width - width, track.width * root.value - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: 4; height: area.containsMouse || area.pressed ? 22 : 18; radius: 2; antialiasing: true
        color: Theme.m.fg
        Behavior on x { NumberAnimation { duration: area.pressed ? 0 : Theme.anim.fast } }
        Behavior on height { NumberAnimation { duration: Theme.anim.fast } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function set(x) { root.moved(Math.max(0, Math.min(1, x / width))); }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => { if (pressed) set(mouse.x); }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
