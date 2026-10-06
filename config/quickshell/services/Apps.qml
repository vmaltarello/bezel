pragma Singleton
// App search for the launcher. Apps used often AND recently rise to the top: every launch adds 1
// to a score that halves every two weeks, so an app you stopped using sinks over time
// (saved in ~/.local/state/quickshell/launches.json as { id: { s: score, t: time of last launch } }).
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property var all: DesktopEntries.applications.values.filter(e => !e.noDisplay)
    property var counts: ({})
    readonly property real halfLife: 14 * 24 * 3600 * 1000

    // score now
    function used(id) {
        const c = counts[id];
        return c ? c.s * Math.pow(0.5, (Date.now() - c.t) / halfLife) : 0;
    }

    function score(e, q) {
        const used = Math.min(30, root.used(e.id));
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
        counts[e.id] = { s: used(e.id) + 1, t: Date.now() };
        store.setText(JSON.stringify(counts));
        // execute() ignores Terminal=true: btop, nvim... would start with no window and exit
        if (e.runInTerminal) Quickshell.execDetached({ command: ["kitty", "-1", "-e", ...e.command], workingDirectory: e.workingDirectory || Quickshell.env("HOME") });
        else e.execute();
    }

    Process { running: true; command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/quickshell"] }
    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/quickshell/launches.json"
        onLoaded: {
            try {
                const c = JSON.parse(text());
                // old files: a plain launch count -> counted as launched now, then it decays
                for (const id in c) if (typeof c[id] === "number") c[id] = { s: c[id], t: Date.now() };
                root.counts = c;
            } catch (e) {}
        }
    }
}
