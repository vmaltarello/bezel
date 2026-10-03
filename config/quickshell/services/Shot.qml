pragma Singleton
// Screenshot: Print (quickshell ipc call shell screenshot) freezes the focused monitor
// and opens the selection (modules/shell/Screenshot.qml): area, window or full screen.
// The result goes to the clipboard and ~/Pictures/Screenshots; with "editor" satty opens.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root
    property bool active: false            // selection open (the frozen image is ready)
    property bool editor: false            // after capturing, open satty for annotations
    property string mode: "area"           // area | window
    // uncompressed PNG (-l 0): 0.1 s instead of 1.4 s; it lives in RAM, size doesn't matter
    readonly property string frozen: Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-screenshot.png"
    property var monitor: null             // captured monitor (from hyprctl): x, y, width, height, scale
    property var windows: []               // visible windows on that monitor, top to bottom, local coordinates
    property int stamp: 0                  // changes on every capture: reloads the image

    function start() {
        if (active || freeze.running) { cancel(); return; }
        const mon = Hyprland.focusedMonitor?.name;
        if (!mon) return;
        freeze.command = ["bash", "-c",
            'grim -l 0 -o "$1" "$2" && printf \'{"m":%s,"c":%s}\' "$(hyprctl -j monitors)" "$(hyprctl -j clients)"',
            "quickshell-screenshot", mon, frozen];
        freeze.running = true;
    }
    function cancel() { active = false; }
    // open panels end up in the capture, then close under the selection
    onActiveChanged: if (active) Ui.close()

    // x, y, w, h in physical pixels of the frozen image; w = 0 = full screen
    function capture(x, y, w, h) {
        active = false;
        save.command = ["bash", "-c", `
            src="$1"; geo="$2"; editor="$3"
            dir=~/Pictures/Screenshots; mkdir -p "$dir"
            out="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
            # light compression: a full screen saves in 0.4 s instead of 2.4 s (file ~25% bigger)
            crop() { magick "$src" \${geo:+-crop "$geo" +repage} -define png:compression-level=1 -define png:compression-filter=5 "$1"; }
            if [ "$editor" = 1 ]; then
                crop png:- | satty --filename - \\
                    --output-filename "$dir/%Y-%m-%d_%H-%M-%S.png" \\
                    --copy-command wl-copy \\
                    --actions-on-enter save-to-clipboard,save-to-file,exit \\
                    --actions-on-escape exit \\
                    --early-exit copy save \\
                    --initial-tool arrow \\
                    --corner-roundness 6 \\
                    --font-family "JetBrainsMono Nerd Font"
            else
                crop "$out" || exit 1
                wl-copy --type image/png < "$out"
                notify-send -a Screenshot -h string:image-path:"$out" "Screenshot saved" "Copied to clipboard · \${out/#$HOME/\\~}"
            fi`,
            "quickshell-screenshot", frozen, w > 0 ? `${w}x${h}+${x}+${y}` : "", editor ? "1" : "0"];
        save.startDetached();
    }

    Process {
        id: freeze
        stdout: StdioCollector {
            onStreamFinished: {
                let data;
                try { data = JSON.parse(text); } catch (e) { return; }
                const m = data.m.find(m => m.focused) ?? data.m[0];
                const ws = [m.activeWorkspace?.id, m.specialWorkspace?.id].filter(id => id);
                // on top: special workspace, then floating windows, then by recent focus
                const rank = c => (c.workspace.id === m.specialWorkspace?.id ? 0 : 2) + (c.floating ? 0 : 1);
                root.windows = data.c
                    .filter(c => c.mapped && !c.hidden && ws.includes(c.workspace.id))
                    .sort((a, b) => rank(a) - rank(b) || a.focusHistoryID - b.focusHistoryID)
                    .map(c => ({ x: c.at[0] - m.x, y: c.at[1] - m.y, w: c.size[0], h: c.size[1], title: c.title, cls: c.class }));
                root.monitor = m;
                root.stamp++;
                root.active = true;
            }
        }
    }
    Process { id: save }
}
