// Volume / brightness / microphone: slides out of the right edge, half height, with two concave fillets.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: win
    readonly property int f: Theme.size.fillet
    readonly property int w: 46
    readonly property int h: 210

    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    margins.right: Theme.size.frame
    implicitWidth: w
    implicitHeight: h + 2 * f
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    mask: Region {}

    property bool ready: false
    Timer { running: true; interval: 16; onTriggered: win.ready = true }
    readonly property bool open: ready && Events.visible

    readonly property real value: Events.kind === "brightness" ? Brightness.percent / 100
                                : Events.kind === "mic" ? (Audio.micMuted ? 0 : 1)
                                : (Audio.muted ? 0 : Math.min(1, Audio.volume))
    readonly property color fill: Events.kind === "brightness" ? Theme.m.fgVariant : Events.kind === "mic" ? (Audio.micMuted ? Theme.m.error : Theme.m.tertiary) : Theme.m.primary
    readonly property string icon: Events.kind === "brightness" ? "light_mode"
                                 : Events.kind === "mic" ? (Audio.micMuted ? "mic_off" : "mic")
                                 : Audio.muted ? "volume_off" : Audio.headphones ? "headphones" : Audio.percent > 60 ? "volume_up" : "volume_down"

    Item {
        id: shape
        anchors.right: parent.right
        width: win.open ? win.w : 0
        height: parent.height
        Behavior on width { NumberAnimation { duration: Theme.anim.normal; easing.type: Easing.OutCubic } }

        Fillet { anchors.right: parent.right; y: 0; corner: "br"; color: Theme.m.barGlass; opacity: shape.width > win.f ? 1 : 0 }
        Fillet { anchors.right: parent.right; y: win.h + win.f; corner: "tr"; color: Theme.m.barGlass; opacity: shape.width > win.f ? 1 : 0 }
        RRect {
            y: win.f
            width: parent.width; height: win.h
            color: Theme.m.barGlass
            topLeftRadius: Theme.size.radius; bottomLeftRadius: Theme.size.radius
            clip: true
            Column {
                anchors.centerIn: parent
                spacing: 10
                opacity: win.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }
                MIcon { anchors.horizontalCenter: parent.horizontalCenter; text: win.icon; filled: true; color: Audio.muted && Events.kind === "volume" ? Theme.m.error : Theme.m.fg; font.pixelSize: 20 }
                RRect {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 8; height: 130; radius: 3; antialiasing: true; color: Theme.m.containerHighest
                    RRect {
                        anchors.bottom: parent.bottom
                        width: parent.width; radius: 3; antialiasing: true; color: win.fill
                        height: parent.height * Math.max(0, Math.min(1, win.value))
                        Behavior on height { NumberAnimation { duration: Theme.anim.fast } }
                    }
                }
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(win.value * 100); font.bold: true; font.pixelSize: Theme.font.small }
            }
        }
    }
}
