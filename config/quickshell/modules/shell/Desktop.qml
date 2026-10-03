// Desktop widgets: above the wallpaper, below windows (Bottom layer).
// Visible on empty workspaces; while covered by windows they don't refresh (see System.seen).
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    anchors { top: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    margins { top: Theme.size.frame + 14; right: Theme.size.frame + 14 }
    implicitWidth: widgets.width
    implicitHeight: widgets.implicitHeight
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-desktop"

    DesktopWidgets { id: widgets }
}
