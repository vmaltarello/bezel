// Launcher (Spotlight style): a search line centered in the upper part of the screen, results below.
// Modes: Apps · Clipboard · Wallpapers · Keys (Tab to switch; windows are in the overview, SUPER+TAB). Prefixes: "=" calculator, ">" command.
// Keys: ↑↓ (←→ for wallpapers) select · Enter open · Shift+Enter command in terminal · Shift+Del delete from clipboard · Esc close.
// The window covers the whole screen (transparent): a click outside the panel closes it
// even with exclusive keyboard focus, which is needed to type right away.
// The QML window is never destroyed: when closed it is unmapped, but only after the close animation
// has committed a fully transparent frame. Keyboard and input are released only AFTER the close animation: as soon as
// they are dropped Hyprland stops sending frame callbacks, so the animation would freeze half way
// (that frozen frame of the empty panel was the close flash).
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    // closed: the window is unmapped (after the close animation), so its fullscreen buffer (~20 MB)
    // is freed; it is mapped again directly at full size. Resizing it instead (1x1 <-> fullscreen)
    // made Hyprland animate the growth from the top-left corner.
    visible: active
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    // open, or still animating closed
    property bool active: false
    // close fade, then a couple of frames to commit the now transparent panel, then keyboard and input are released
    readonly property int closeMs: 200
    Timer { id: settle; interval: win.closeMs + 60; onTriggered: win.active = false }
    // the window has grown to the whole screen and the compositor shows it at full size:
    // only now the panel may appear (otherwise it slides while the window grows)
    readonly property bool full: active && width > 1 && height > 1
    property bool sized: false
    onFullChanged: { if (full) sizedDelay.restart(); else { sizedDelay.stop(); sized = false; } }
    Timer { id: sizedDelay; interval: 40; onTriggered: win.sized = true }
    readonly property bool shown: open && sized
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // closed: empty input region, clicks go through to the windows
    mask: Region { x: 0; y: 0; width: win.active ? win.width : 0; height: win.active ? win.height : 0 }

    readonly property bool open: Ui.panel === "launcher"

    readonly property var modes: [["apps", "Apps"], ["clipboard", "Clipboard"], ["wallpapers", "Wallpapers"], ["keys", "Keys"]]
    readonly property string mode: Ui.launcherMode
    property string query: ""          // written by the search field in LauncherPanel
    // effective mode: the "=" and ">" prefixes win
    readonly property string kind: query.startsWith("=") ? "calc" : query.startsWith(">") ? "cmd" : mode
    property int current: 0

    onModeChanged: { query = ""; current = 0; if (mode === "clipboard") Clip.refresh(); if (mode === "keys") bindsProc.running = true; }
    onQueryChanged: current = 0
    // every opening starts clean and refreshes the data of the current mode
    onOpenChanged: {
        if (!open) { settle.restart(); return; }
        settle.stop(); active = true;
        query = ""; current = 0;
        if (mode === "clipboard") Clip.refresh();
        if (mode === "keys") bindsProc.running = true;
    }

    // ---------- results ----------
    function calc(q) {
        const expr = q.replace(/^=/, "").replace(/,/g, ".").replace(/\^/g, "**").trim();
        if (!expr || !/^[\d\s+\-*/().%*]+$/.test(expr)) return null;
        try {
            const v = Function('"use strict"; return (' + expr + ")")();
            return Number.isFinite(v) ? String(Math.round(v * 1e10) / 1e10) : null;
        } catch (e) { return null; }
    }
    readonly property var system: [
        ["lock", "Lock", ["loginctl", "lock-session"]],
        ["bedtime", "Suspend", ["systemctl", "suspend"]],
        ["logout", "Log out", ["hyprshutdown", "-t", "Logging out..."]],
        ["restart_alt", "Reboot", ["hyprshutdown", "-t", "Rebooting...", "-p", "systemctl reboot"]],
        ["power_settings_new", "Shut down", ["hyprshutdown", "-t", "Shutting down...", "-p", "systemctl poweroff"]]
    ]
    readonly property var results: {
        const q = query.trim().toLowerCase();
        if (kind === "calc") {
            const r = calc(query);
            return [{ sym: "calculate", title: r ?? "…", sub: r ? "Enter to copy" : "Type an expression, e.g. =12*7", run: () => { if (r) Quickshell.execDetached(["wl-copy", r]); } }];
        }
        if (kind === "cmd") {
            const c = query.slice(1).trim();
            return [{ sym: "terminal", title: c || "…", sub: c ? "Enter to run · Shift+Enter in terminal" : "Type a command", run: shift => {
                if (!c) return;
                if (shift) Quickshell.execDetached(["kitty", "-1", "--class", "kitty-float", "-e", "sh", "-c", c + '; echo; read -n1 -p "Press a key…"']);
                else Quickshell.execDetached(["sh", "-c", c]);
            } }];
        }
        if (kind === "keys") {
            return binds.filter(b => !q || (b.combo + " " + b.desc).toLowerCase().includes(q))
                .map(b => ({ sym: "keyboard", title: b.desc, sub: b.combo, run: () => {} }));
        }
        if (kind === "clipboard") {
            return Clip.items.filter(i => !q || i.text.toLowerCase().includes(q)).slice(0, 50)
                .map(i => ({ sym: i.text.startsWith("Image ") ? "image" : "content_paste", title: i.text.replace(/\s+/g, " ").slice(0, 120), sub: "", line: i.line, run: () => Clip.copy(i.line) }));
        }
        // apps (+ system commands when the query names them)
        const apps = Apps.search(q, 40).map(e => ({ icon: Quickshell.iconPath(e.icon, true), title: e.name, sub: e.genericName || e.comment || "", run: () => Apps.launch(e) }));
        const sys = q ? system.filter(s => s[1].toLowerCase().includes(q)).map(s => ({ sym: s[0], title: s[1], sub: "System", run: () => Quickshell.execDetached(s[2]) })) : [];
        const r = calc(q);
        return (r !== null ? [{ sym: "calculate", title: r, sub: "Enter to copy", run: () => Quickshell.execDetached(["wl-copy", r]) }] : []).concat(sys, apps);
    }

    function activate(i, shift) {
        if (kind === "wallpapers") {
            const p = walls.get(i, "filePath");
            if (p) Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper.sh", p]);
            Ui.close();
            return;
        }
        const r = results[i];
        if (!r) return;
        Ui.close();
        r.run(shift);
    }
    function move(d) {
        const n = kind === "wallpapers" ? wallIdx.length : results.length;
        if (n) current = (current + d + n) % n;
    }

    // shortcuts read from Hyprland (bind descriptions in hyprland.lua)
    property var binds: []
    Process {
        id: bindsProc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const MODS = [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]];
                const KEYS = { "mouse:272": "left click", "mouse:273": "right click", "mouse_down": "wheel", "mouse_up": "wheel",
                               left: "←", right: "→", up: "↑", down: "↓", TAB: "Tab", SPACE: "Space" };
                const out = [], seen = {};
                for (const b of JSON.parse(text)) {
                    if (!b.description) continue;
                    let combo, desc = b.description;
                    if (b.key.startsWith("XF86")) { combo = "Fn keys"; desc = "Volume · brightness · mic · media"; }
                    else {
                        const mods = MODS.filter(m => b.modmask & m[0]).map(m => m[1]);
                        if (b.key === "SUPER_L") combo = "SUPER (alone)";
                        else {
                            const k = /^\d$/.test(b.key) ? "0-9" : ["left", "right", "up", "down"].includes(b.key) ? "arrows" : (KEYS[b.key] ?? b.key);
                            combo = mods.concat([k]).join(" + ");
                        }
                    }
                    if (seen[combo + desc]) continue;
                    seen[combo + desc] = true;
                    out.push({ combo, desc });
                }
                win.binds = out;
            }
        }
    }

    readonly property alias walls: wallsModel
    FolderListModel {
        id: wallsModel
        folder: "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers"
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
        sortField: FolderListModel.Name
    }
    // wallpapers filtered by name
    readonly property var wallIdx: {
        const q = query.trim().toLowerCase(), out = [];
        for (let i = 0; i < walls.count; i++) if (!q || walls.get(i, "fileName").toLowerCase().includes(q)) out.push(i);
        return out;
    }

    // click outside the panel = close
    Rectangle { anchors.fill: parent; color: "transparent" }
    MouseArea { anchors.fill: parent; onPressed: Ui.close() }

    // ---------- panel (Spotlight style): centered, upper part of the screen ----------
    // macOS Spotlight style: opening = quick fade + zoom from 94% with a slight bounce, anchored at
    // the search line; closing = soft fade + slight shrink. Keyboard and input are kept until the
    // close animation ends (see settle), so it runs to the end instead of freezing.
    Item {
        id: box
        x: Math.round(Theme.size.barWidth + (win.width - Theme.size.barWidth - Theme.size.frame - width) / 2)
        y: Math.round(win.height * 0.2)
        width: panel.width; height: panel.implicitHeight
        visible: win.sized
        transformOrigin: Item.Top
        opacity: win.shown ? 1 : 0
        scale: win.shown ? 1 : (win.open ? 0.94 : 0.96)
        Behavior on opacity {
            NumberAnimation { duration: win.shown ? 160 : win.closeMs; easing.type: win.shown ? Easing.OutCubic : Easing.OutQuad }
        }
        Behavior on scale {
            NumberAnimation {
                duration: win.shown ? 320 : win.closeMs
                easing.type: win.shown ? Easing.OutBack : Easing.OutQuad
                easing.overshoot: 1.1
            }
        }
        MouseArea { anchors.fill: parent }    // clicks inside don't close
        LauncherPanel { id: panel; win: win }
    }
}
