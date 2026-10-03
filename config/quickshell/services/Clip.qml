pragma Singleton
// Clipboard history (cliphist). Read when the launcher's Clipboard tab opens.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var items: []          // [{ line, text }] (line = full cliphist line, needed to copy/delete)

    function refresh() { list.running = true; }
    function copy(line) { Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", line]); }
    function remove(line) {
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", line]);
        items = items.filter(i => i.line !== line);
    }

    Process {
        id: list
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.items = text.split("\n").filter(l => l).slice(0, 200).map(l => {
                const t = l.split("\t").slice(1).join("\t");
                return { line: l, text: t.startsWith("[[ binary") ? "Image " + (t.match(/\d+x\d+/)?.[0] ?? "") : t };
            })
        }
    }
}
