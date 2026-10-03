// Bar side menu: ONE panel for all of them (network, bluetooth, audio, battery, session).
// It grows out of the bar; moving to another icon it slides vertically to it,
// adapts width and height and crossfades the content: no jumps.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: win
    readonly property int f: Theme.size.fillet
    readonly property int maxW: 360

    anchors { left: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    margins.left: Theme.size.barWidth
    implicitWidth: maxW
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-panel"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: shape }

    property bool ready: false
    Timer { running: true; interval: 16; onTriggered: win.ready = true }
    readonly property bool open: ready && Ui.sidePanels.includes(Ui.panel)

    // current content (the last one stays while closing)
    property string current: Ui.panel
    Connections { target: Ui; function onPanelChanged() { if (Ui.sidePanels.includes(Ui.panel)) win.current = Ui.panel; } }
    readonly property var components: ({ net: netC, bt: btC, audio: audioC, battery: batteryC, power: powerC })

    readonly property int contentW: loader.item ? loader.item.panelWidth : 300
    readonly property int contentH: (loader.item ? loader.item.implicitHeight : 0) + 28
    // centered on the icon, without leaving the screen
    readonly property real targetY: Math.round(Math.max(Theme.size.frame, Math.min(height - Theme.size.frame - contentH - 2 * f, Ui.anchorY - contentH / 2 - f)))

    Component.onDestruction: Ui.hoverPanel = false

    Item {
        id: shape
        y: win.targetY
        width: win.open ? win.contentW : 0
        height: win.contentH + 2 * win.f
        Behavior on y { enabled: shape.width > 0; NumberAnimation { duration: Theme.anim.normal; easing.type: Easing.OutCubic } }
        Behavior on height { enabled: shape.width > 0; NumberAnimation { duration: Theme.anim.normal; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: Theme.anim.slow; easing.type: Easing.OutCubic } }
        HoverHandler { onHoveredChanged: Ui.hoverPanel = hovered }

        Fillet { y: 0; corner: "bl"; color: Theme.m.barGlass; opacity: shape.width > win.f ? 1 : 0 }
        Fillet { y: shape.height - win.f; corner: "tl"; color: Theme.m.barGlass; opacity: shape.width > win.f ? 1 : 0 }
        RRect {
            y: win.f
            width: parent.width; height: parent.height - 2 * win.f
            color: Theme.m.barGlass
            topRightRadius: Theme.size.radius; bottomRightRadius: Theme.size.radius
            clip: true

            Loader {
                id: loader
                x: 16; y: 14
                sourceComponent: win.components[win.current] ?? null
                opacity: win.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.anim.normal } }
                // menu change: the new content fades in
                onSourceComponentChanged: if (win.open) fade.restart()
                NumberAnimation { id: fade; target: loader; property: "opacity"; from: 0; to: 1; duration: Theme.anim.normal }
            }
        }
    }
    Item { focus: win.open; Keys.onEscapePressed: Ui.close() }

    Component { id: netC; NetPanel {} }
    Component { id: btC; BtPanel {} }
    Component { id: audioC; AudioPanel {} }
    Component { id: batteryC; BatteryPanel {} }
    Component { id: powerC; PowerPanel {} }
}
