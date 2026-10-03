// Invisible layer that exists only while a panel is open: a click outside the panel closes it.
// The bar is left out, so you can go straight from one menu to another.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-catcher"
    // clickable region with explicit size (bound to an item it came out empty and clicks went through)
    mask: Region { x: Theme.size.barWidth; y: 0; width: (win.screen?.width ?? 1440); height: (win.screen?.height ?? 960) }

    Rectangle { anchors.fill: parent; color: "transparent" }
    MouseArea {
        id: hit
        anchors { fill: parent; leftMargin: Theme.size.barWidth }
        acceptedButtons: Qt.AllButtons
        onPressed: Ui.close()
    }
}
