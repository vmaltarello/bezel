// Screen frame: three thin strips (top, right, bottom) + the rounded corners.
// Not a fullscreen window: just strips, so it is very cheap.
// The rounded corners cover the outer window corners: with two windows side by side
// the left one is rounded on the left, the right one on the right; a single window on all four.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components

Scope {
    id: root
    required property var screen
    readonly property int t: Theme.size.frame
    readonly property int r: Theme.size.frameRadius
    readonly property int bw: Theme.size.barWidth

    component Strip: PanelWindow {
        screen: root.screen
        color: "transparent"
        mask: Region {}                       // no mouse input: clicks go to the windows
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-frame"
    }

    // top: strip + rounded corners top left (next to the bar) and top right
    Strip {
        anchors { top: true; left: true; right: true }
        implicitHeight: root.t + root.r
        exclusiveZone: root.t
        // translucent: the bar sits between top and bottom strips (exclusive zones), so nothing overlaps
        Rectangle { width: parent.width; height: root.t; color: Theme.m.barGlass }
        Fillet { x: root.bw; y: root.t; r: root.r; corner: "tl"; color: Theme.m.barGlass }
        Fillet { x: parent.width - root.t - root.r; y: root.t; r: root.r; corner: "tr"; color: Theme.m.barGlass }
    }
    // bottom
    Strip {
        anchors { bottom: true; left: true; right: true }
        implicitHeight: root.t + root.r
        exclusiveZone: root.t
        Rectangle { y: root.r; width: parent.width; height: root.t; color: Theme.m.barGlass }
        Fillet { x: root.bw; y: 0; r: root.r; corner: "bl"; color: Theme.m.barGlass }
        Fillet { x: parent.width - root.t - root.r; y: 0; r: root.r; corner: "br"; color: Theme.m.barGlass }
    }
    // right (the corners are drawn by the top and bottom strips)
    Strip {
        anchors { right: true; top: true; bottom: true }
        implicitWidth: root.t
        exclusiveZone: root.t
        Rectangle { anchors.fill: parent; color: Theme.m.barGlass }
    }
}
