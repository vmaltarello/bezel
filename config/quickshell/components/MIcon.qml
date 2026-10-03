// Material Symbols Rounded icon by name ("wifi", "volume_up"...). filled = active state.
import QtQuick
import qs.config

Text {
    property bool filled: false
    property int weight: 500
    font.family: Theme.font.symbols
    font.pixelSize: 22
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "wght": weight, "opsz": 24 })
    color: Theme.m.fg
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.QtRendering
}
