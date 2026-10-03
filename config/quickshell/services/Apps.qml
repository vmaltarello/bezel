pragma Singleton
// App search for the launcher. Most used apps rise to the top
// (counts saved in ~/.local/state/quickshell/launches.json).
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property var all: DesktopEntries.applications.values.filter(e => !e.noDisplay)
    property var counts: ({})

    function score(e, q) {
        const used = Math.min(30, counts[e.id] ?? 0);
        if (!q) return used;
        const n = (e.name ?? "").toLowerCase();
        const extra = ((e.genericName ?? "") + " " + (e.keywords ?? []).join(" ") + " " + (e.comment ?? "")).toLowerCase();
        let s = 0;
        if (n.startsWith(q)) s = 100;
        else if (n.split(/[\s\-_.]+/).some(w => w.startsWith(q))) s = 80;
        else if (n.includes(q)) s = 60;
        else if (extra.includes(q)) s = 40;
        else {
            // letters in order, not necessarily adjacent ("zn" -> "zen")
            let i = 0;
            for (const c of n) if (c === q[i]) i++;
            if (i === q.length) s = 20;
        }
        return s ? s + used : 0;
    }

    function search(q, limit) {
        q = q.trim().toLowerCase();
        return all.map(e => ({ e, s: score(e, q) }))
                  .filter(x => q ? x.s > 0 : true)
                  .sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name))
                  .slice(0, limit)
                  .map(x => x.e);
    }

    function launch(e) {
        counts[e.id] = (counts[e.id] ?? 0) + 1;
        store.setText(JSON.stringify(counts));
        e.execute();
    }

    Process { running: true; command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/quickshell"] }
    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/quickshell/launches.json"
        onLoaded: { try { root.counts = JSON.parse(text()); } catch (e) {} }
    }
}
