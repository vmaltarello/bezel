pragma Singleton
// Which panel is open: "" (none) | overview | launcher | net | bt | audio | battery | power
// One panel at a time. Terminal commands and shortcuts:
//   quickshell ipc call shell panel <name>      (opens/closes a panel)
//   quickshell ipc call shell close
//   quickshell ipc call shell launcher apps|clipboard|wallpapers|keys
//   quickshell ipc call shell search <text>    (launcher with text typed, e.g. "=" calculator)
//   quickshell ipc call shell lock              (lock screen, used by hypridle)
//   quickshell ipc call shell dnd               (do not disturb on/off)
//   quickshell ipc call shell overview toggle|open|close   (SUPER+TAB, 3 fingers up/down: overview)
//   quickshell ipc call shell screenshot        (Print: select area/window/screen)
//   quickshell ipc call shell event brightness|mic   (from osd.sh)
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config

Singleton {
    id: root
    property string panel: ""
    property bool locked: false         // lock screen (modules/lock)
    // stays set during the close animation, then the window is destroyed
    property string shown: ""
    signal launcherType(string text)    // IPC "search": text to put in the launcher field
    property string launcherMode: "apps"   // apps | clipboard | wallpapers | keys
    property real anchorY: 760          // y of the clicked bar icon (for the side menus)
    // desktop widgets are visible: empty workspace
    readonly property bool desktopSeen: !locked && (Hyprland.focusedWorkspace?.toplevels.values.length ?? 1) === 0

    function toggle(name) { byHover = false; panel = panel === name ? "" : name; }

    // ---- side menus on hover ----
    readonly property var sidePanels: ["net", "bt", "audio", "battery", "power"]
    property string hoverIcon: ""       // bar icon under the mouse ("" = none)
    property real hoverY: 0
    property bool hoverPanel: false     // mouse inside the open menu
    property bool byHover: false        // the menu was opened by hovering (closes when leaving)
    onHoverIconChanged: {
        if (hoverIcon) { hoverClose.stop(); hoverOpen.restart(); }
        else { hoverOpen.stop(); hoverClose.restart(); }
    }
    onHoverPanelChanged: hoverPanel ? hoverClose.stop() : hoverClose.restart()
    Timer {
        id: hoverOpen; interval: 150
        onTriggered: {
            if (!root.hoverIcon || root.panel === root.hoverIcon) return;
            if (root.panel === "" || (root.sidePanels.includes(root.panel) && root.byHover)) {
                root.anchorY = root.hoverY;
                root.panel = root.hoverIcon;
                root.byHover = true;
            }
        }
    }
    Timer {
        id: hoverClose; interval: 350
        onTriggered: if (root.byHover && !root.hoverIcon && !root.hoverPanel && root.sidePanels.includes(root.panel)) root.panel = ""
    }
    function close() { panel = ""; byHover = false; }

    onPanelChanged: {
        if (panel) { closing.stop(); shown = panel; }
        else closing.restart();
    }
    Timer { id: closing; interval: Theme.anim.slow + 60; onTriggered: if (!root.panel) root.shown = "" }

    // overview: first a capture of every window (grim -T: works for covered windows and other
    // workspaces too, ~60 ms each, in parallel), then it opens. Files in $XDG_RUNTIME_DIR/quickshell-overview/<stableId>.ppm
    // (ppm: uncompressed, written and decoded faster than png)
    readonly property string overviewDir: Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-overview"
    property int overviewStamp: 0
    // windows read at the same time as the captures: "0xaddress" -> { at, size, visible, id }
    // (visible = false: covered by another, e.g. a maximized one; id = stableId, capture file name)
    property var overviewGeo: ({})
    function openOverview() {
        overviewShot.command = ["bash", "-c", `
            dir="$1"; rm -rf "$dir"; mkdir -p "$dir"
            clients=$(hyprctl -j clients)
            jq -r '.[] | select(.mapped and .workspace.id > 0) | .stableId' <<<"$clients" \
                | xargs -P 8 -I{} grim -t ppm -T {} "$dir/{}.ppm" 2>/dev/null
            printf '%s' "$clients"`, "quickshell-overview", overviewDir];
        overviewShot.running = true;
    }
    Process {
        id: overviewShot
        stdout: StdioCollector {
            onStreamFinished: {
                const geo = {};
                try { for (const c of JSON.parse(text)) geo[c.address] = { at: c.at, size: c.size, visible: c.visible, id: c.stableId }; } catch (e) {}
                root.overviewGeo = geo;
                root.overviewStamp++;
                root.toggle("overview");
            }
        }
    }

    IpcHandler {
        target: "shell"
        function panel(name: string): void { root.toggle(name); }
        function close(): void { root.close(); }
        // launcher: apps | clipboard | wallpapers | keys (same mode twice = close)
        function launcher(mode: string): void {
            if (root.panel === "launcher" && root.launcherMode === mode) { root.close(); return; }
            root.launcherMode = mode || "apps";
            root.panel = "launcher";
        }
        // open the launcher with text already typed, e.g. "=" for the calculator
        function search(text: string): void {
            if (root.panel !== "launcher") { root.launcherMode = "apps"; root.panel = "launcher"; }
            Qt.callLater(() => root.launcherType(text));
        }
        function lock(): void { root.close(); root.locked = true; }
        function dnd(): void { Dnd.toggle(); }
        function overview(action: string): void {
            const isOpen = root.panel === "overview";
            if (action === "close" || (action !== "open" && isOpen)) { if (isOpen) root.close(); }
            else if (!isOpen && !overviewShot.running) root.openOverview();
        }
        function screenshot(): void { Shot.start(); }
        // media keys (instead of playerctl)
        function media(action: string): void {
            if (action === "next") Media.next();
            else if (action === "prev") Media.previous();
            else Media.toggle();
        }
        function event(kind: string): void {
            if (kind === "brightness") Brightness.reload();
            Events.show(kind);
        }
    }
}
