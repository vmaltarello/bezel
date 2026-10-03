// Peek at the desktop (SUPER alone or click on the bar clock): windows fade away, widgets show.
// Actually the wallpaper + widgets fade in above the windows; bar and frame stay.
// Click, any key or SUPER again: back to the windows.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-peek"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: area }

    property bool ready: false
    Timer { running: true; interval: 16; onTriggered: win.ready = true }
    readonly property bool open: ready && Ui.panel === "peek"

    readonly property int t: Theme.size.frame
    readonly property int r: Theme.size.frameRadius

    // only the area inside the frame: the bar stays visible
    Item {
        id: area
        x: Theme.size.barWidth; y: win.t
        width: win.width - x - win.t; height: win.height - 2 * win.t
        clip: true
        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim.normal; easing.type: Easing.OutCubic } }

        Image {
            x: -area.x; y: -area.y
            width: win.width; height: win.height
            source: "file://" + Quickshell.env("HOME") + "/.local/state/wallpaper"
            sourceSize.width: width * (win.screen?.devicePixelRatio ?? 1.5)
            fillMode: Image.PreserveAspectCrop
            cache: false
        }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: Ui.close() }

        DesktopWidgets {
            anchors { top: parent.top; right: parent.right; topMargin: 14; rightMargin: 14 }
            // small slide-in
            transform: Translate { x: win.open ? 0 : 24; Behavior on x { NumberAnimation { duration: Theme.anim.slow; easing.type: Easing.OutCubic } } }
        }

        // frame corners (the real ones are below this window)
        Fillet { visible: Theme.size.hasFrame; x: 0; y: 0; r: win.r; corner: "tl"; color: Theme.m.barGlass }
        Fillet { visible: Theme.size.hasFrame; x: area.width - win.r; y: 0; r: win.r; corner: "tr"; color: Theme.m.barGlass }
        Fillet { visible: Theme.size.hasFrame; x: 0; y: area.height - win.r; r: win.r; corner: "bl"; color: Theme.m.barGlass }
        Fillet { visible: Theme.size.hasFrame; x: area.width - win.r; y: area.height - win.r; r: win.r; corner: "br"; color: Theme.m.barGlass }
    }

    Item {
        focus: win.open
        // any key closes, except SUPER: its release is the toggle bind itself (closing here would reopen it)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || event.key === Qt.Key_Meta) return;
            Ui.close(); event.accepted = true;
        }
    }
}
