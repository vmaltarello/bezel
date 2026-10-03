// Text with the theme font and color.
import QtQuick
import qs.config

Text {
    color: Theme.c.fg
    font.family: Theme.font.family
    font.pixelSize: Theme.font.normal
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
