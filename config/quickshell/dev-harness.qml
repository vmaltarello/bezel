// Dev tool: renders the side menus offscreen and saves a PNG of each, without touching the real screen.
//   QT_QPA_PLATFORM=offscreen quickshell -p ~/.config/quickshell/dev-harness.qml
// Output: $XDG_RUNTIME_DIR/quickshell-harness/menus.png (side menus) and launcher.png
// HARNESS=launcher | widgets renders the launcher panel or the desktop widgets instead.
//@ pragma Env QT_QUICK_BACKEND=software
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import qs.config
import qs.services
import "modules/shell"
import "modules/lock"

ShellRoot {
    readonly property string what: Quickshell.env("HARNESS") || "menus"
    // launcher panel with a fake window object (state only, no layer shell)
    FloatingWindow {
        visible: what === "launcher"
        implicitWidth: 712; implicitHeight: 460
        color: Theme.c.frame
        QtObject {
            id: fake
            property bool open: true
            property string mode: Quickshell.env("HARNESS_MODE") || "apps"
            property string kind: mode
            property string query: ""
            property int current: mode === "wallpapers" ? Math.max(0, wallFolder.count - 1) : 1
            property int rowH: 50
            property int listH: 4 * 50
            property var modes: [["apps", "Apps"], ["clipboard", "Clipboard"], ["wallpapers", "Wallpapers"], ["keys", "Keys"]]
            property var results: Apps.search("", 6).map(e => ({ icon: Quickshell.iconPath(e.icon, true), title: e.name, sub: e.genericName || e.comment || "" }))
                .concat([{ sym: "lock", title: "Lock", sub: "System" }])
            // wallpapers mode: real folder, selection on the last one (forces the grid to scroll)
            property var wallIdx: { const o = []; for (let i = 0; i < wallFolder.count; i++) o.push(i); return o; }
            property var walls: wallFolder
            function move(d) {}
            function activate(i, s) {}
        }
        FolderListModel {
            id: wallFolder
            folder: "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers"
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
            showDirs: false
        }
        LauncherPanel { id: lp; x: 16; y: 14; win: fake }
        Timer {
            interval: 2500; running: what === "launcher"
            onTriggered: lp.grabToImage(r => { r.saveToFile(Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-harness/launcher.png"); Qt.quit(); })
        }
    }
    // lock screen with a fake state (HARNESS=lock, HARNESS_TYPED=n characters typed)
    FloatingWindow {
        visible: what === "lock"
        implicitWidth: 1440; implicitHeight: 960
        color: "black"
        QtObject {
            id: fakeLock
            property string buffer: "x".repeat(Number(Quickshell.env("HARNESS_TYPED") || 0))
            property bool busy: false
            property bool unlocking: false
            property int fails: 0
            property string message: Quickshell.env("HARNESS_MSG") || ""
            function submit() {}
            function clear() {}
        }
        Item {
            id: lockBox
            anchors.fill: parent
            LockView { anchors.fill: parent; ctx: fakeLock; greeter: Quickshell.env("HARNESS_GREETER") === "1" }
        }
        Timer {
            interval: 2500; running: what === "lock"
            onTriggered: lockBox.grabToImage(r => { r.saveToFile(Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-harness/lock.png"); Qt.quit(); })
        }
    }
    FloatingWindow {
        visible: what === "menus" || what === "widgets"
        id: w
        implicitWidth: 1100; implicitHeight: 700
        color: Theme.c.frame
        Row {
            id: row
            x: 16; y: 16; spacing: 24
            Repeater {
                model: what === "widgets" ? ["widgets"] : ["net", "bt", "audio", "battery", "power"]
                Loader {
                    required property string modelData
                    source: "modules/shell/" + ({ net: "NetPanel", bt: "BtPanel", audio: "AudioPanel", battery: "BatteryPanel", power: "PowerPanel", widgets: "DesktopWidgets" })[modelData] + ".qml"
                }
            }
        }
        Timer {
            interval: 2500; running: what === "menus" || what === "widgets"
            onTriggered: row.grabToImage(r => { r.saveToFile(Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-harness/" + what + ".png"); Qt.quit(); })
        }
    }
}
