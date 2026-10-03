pragma Singleton
// Available updates (pacman + AUR), checked every hour.
// checkupdates uses a temporary copy of the sync db: no root, system db untouched.
// AUR updates are counted only if an AUR helper (paru or yay) is installed.
// upgrade() runs the helper (or sudo pacman -Syu) in a floating kitty and re-checks when it closes.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property int count: 0
    property var list: []            // "package old -> new"
    readonly property bool upgrading: upgradeProc.running

    // shell snippet: $h = first AUR helper found, empty if none
    readonly property string helper: "h=$(command -v paru || command -v yay); "

    function check() { if (!checkProc.running && !upgradeProc.running) checkProc.running = true; }
    function upgrade() { if (!upgradeProc.running) upgradeProc.running = true; }

    // first check one minute after start (doesn't slow login), then hourly
    Timer { interval: 60000; running: true; onTriggered: root.check() }
    Timer { interval: 3600000; running: true; repeat: true; onTriggered: root.check() }

    Process {
        id: checkProc
        command: ["sh", "-c", root.helper + "{ checkupdates; [ -n \"$h\" ] && $h -Qua 2>/dev/null; } | grep -v '\\[ignored\\]'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.list = text.split("\n").filter(l => l.trim() !== "");
                root.count = root.list.length;
            }
        }
    }
    Process {
        id: upgradeProc
        command: ["kitty", "--class", "kitty-float", "-e", "sh", "-c",
                  root.helper + "if [ -n \"$h\" ]; then $h; else sudo pacman -Syu; fi; echo; read -rp 'Done. Press Enter to close ' _"]
        onExited: root.check()
    }
}
