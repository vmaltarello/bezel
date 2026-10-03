pragma Singleton
// Events that show the OSD on the right edge: volume, brightness, microphone.
// Stays visible 2.4 s after the last event, then hides (and its window is destroyed).
import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root
    property string kind: ""        // volume | brightness | mic
    property bool visible: false
    readonly property bool loaded: visible || hiding.running

    // at startup services "change" values while loading: ignore the first seconds
    property bool armed: false
    Timer { running: true; interval: 3000; onTriggered: root.armed = true }

    // event kinds that show the OSD
    readonly property var osdKinds: ["volume", "brightness", "mic"]
    function show(k) {
        if (!armed || !osdKinds.includes(k)) return;
        kind = k;
        visible = true;
        timeout.restart();
    }

    Timer { id: timeout; interval: 2400; onTriggered: { root.visible = false; hiding.restart(); } }
    Timer { id: hiding; interval: Theme.anim.slow + 50 }

    Connections {
        target: Audio
        function onPercentChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
    }
    // brightness and mic are reported by ~/.config/hypr/scripts/osd.sh ("event" command in Ui.qml)
}
