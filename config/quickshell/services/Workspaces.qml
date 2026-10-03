pragma Singleton
// Workspaces with their windows (position and size), for the bar and the overview.
// Uses the data Hyprland already has: no screen capture.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

Singleton {
    id: root
    readonly property var wss: Hyprland.workspaces.values.filter(w => w.id > 0)
    readonly property int activeId: Hyprland.focusedWorkspace?.id ?? 1
    // the persistent ones, plus higher workspaces only while they contain windows
    readonly property int count: Math.max(Config.persistentWorkspaces, ...wss.filter(w => w.toplevels.values.length > 0).map(w => w.id))

    function byId(id) { return wss.find(w => w.id === id) ?? null; }

    // app class of a window: the Wayland app id is live, lastIpcObject is filled only after a refresh
    function appClass(t) { return t.wayland?.appId || t.lastIpcObject?.class || ""; }

    // window opened/closed/moved: refresh the toplevel data (debounced)
    Connections {
        target: Hyprland
        function onRawEvent(e) {
            if (["openwindow", "closewindow", "movewindow", "movewindowv2"].includes(e.name)) toplevelRefresh.restart();
        }
    }
    Timer { id: toplevelRefresh; interval: 100; onTriggered: Hyprland.refreshToplevels() }
    Component.onCompleted: Hyprland.refreshToplevels()

    // windows of a workspace: { cls, title, x, y, w, h } with x/y/w/h between 0 and 1
    function windows(id) {
        const ws = byId(id);
        if (!ws) return [];
        const mon = ws.monitor;
        const mw = mon ? mon.width / mon.scale : 1440, mh = mon ? mon.height / mon.scale : 960;
        const mx = mon?.x ?? 0, my = mon?.y ?? 0;
        return ws.toplevels.values.map(t => {
            const o = t.lastIpcObject ?? {};
            const at = o.at ?? [0, 0], sz = o.size ?? [mw, mh];
            return { cls: o.class ?? "", title: t.title, active: t.activated,
                     x: (at[0] - mx) / mw, y: (at[1] - my) / mh, w: sz[0] / mw, h: sz[1] / mh };
        }).filter(w => w.w > 0 && w.h > 0);
    }

    function names(id) {
        const seen = [];
        for (const w of windows(id)) { const n = prettyName(w.cls); if (n && !seen.includes(n)) seen.push(n); }
        return seen.join(", ");
    }
    // the app list loads in the background at startup: reading it here recomputes names and icons once it is ready
    readonly property int appsReady: DesktopEntries.applications.values.length

    function prettyName(cls) {
        appsReady;
        const e = DesktopEntries.heuristicLookup(cls);
        return e?.name ?? cls;
    }
    function icon(cls) {
        appsReady;
        const e = DesktopEntries.heuristicLookup(cls);
        return e ? Quickshell.iconPath(e.icon, true) : "";
    }

    function go(id) { Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`); }

    // fresh positions on demand (e.g. when the overview opens)
    function refresh() { Hyprland.refreshToplevels(); Hyprland.refreshWorkspaces(); }
}
