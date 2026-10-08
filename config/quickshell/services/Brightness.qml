pragma Singleton
// Laptop screen brightness (brightnessctl to write, /sys to read).
// The backlight device is detected at startup; desktops without one get available = false.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string dev: ""
    readonly property bool available: dev !== ""
    Process {
        running: true
        command: ["sh", "-c", "ls -d /sys/class/backlight/* 2>/dev/null | head -1"]
        stdout: StdioCollector { onStreamFinished: root.dev = text.trim() }
    }
    property int max: 1
    property int raw: 0
    readonly property int percent: Math.round(100 * raw / max)

    function set(p) {
        p = Math.max(1, Math.min(100, Math.round(p)));
        Quickshell.execDetached(["brightnessctl", "-n2", "set", p + "%"]);
        raw = Math.round(max * p / 100);
    }
    function step(delta) { set(percent + delta); }

    FileView { path: root.available ? root.dev + "/max_brightness" : ""; onLoaded: max = Number(text()) || 1 }
    // re-read when needed: brightness keys (osd.sh -> Events) and while the menus are open
    function reload() { cur.reload(); }
    // "brightness" (the value we set), not "actual_brightness": on some panels (amdgpu) the latter
    // follows a non-linear hardware curve, so 100% read back as 98% and 50% as 18%
    FileView {
        id: cur; path: root.available ? root.dev + "/brightness" : ""
        onLoaded: raw = Number(text())
    }
    Timer { interval: 1000; running: root.available && Ui.panel === "audio"; repeat: true; onTriggered: cur.reload() }
}
