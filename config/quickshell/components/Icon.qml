// Nerd Font icon, with optional hover and click.
import QtQuick
import qs.config

Txt {
    id: root
    property bool clickable: false
    property bool inkCenter: false   // no longer needed: the "Propo" font already centers glyphs
    // "Propo" font variant: each glyph has its real width, so it centers correctly
    // (in the regular variant glyphs overflow to the right of their cell)
    font.family: Theme.font.icons
    property color hoverColor: color
    readonly property bool hovered: mouse.containsMouse
    signal clicked(var mouse)
    signal scrolled(int delta)

    font.pixelSize: Theme.font.large
    horizontalAlignment: Text.AlignHCenter

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        enabled: root.clickable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.scrolled(wheel.angleDelta.y)
    }
}
