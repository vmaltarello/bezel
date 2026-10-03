// Mission Control style overview (3 fingers up or SUPER+TAB; 3 fingers down closes).
// Workspaces on top (layout with window icons), in the middle the windows of the current
// workspace with the capture taken on opening (one per window, covered ones too: Ui.openOverview): they start from their real position and move into a grid.
// Click a window = focus · middle click = close it · drag it onto a workspace = move it
// Click a workspace = go · keys: ←→ pick window · Enter focus · 1..9 workspace · Esc close.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-overview"
    WlrLayershell.keyboardFocus: open && !pendingWs ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool ready: false
    Timer { running: true; interval: 16; onTriggered: win.ready = true }
    readonly property bool open: ready && Ui.panel === "overview"
    Component.onCompleted: { Hyprland.refreshToplevels(); current = Math.max(0, wins.findIndex(t => t.activated)); }

    readonly property var mon: Hyprland.focusedMonitor
    readonly property real monW: mon ? mon.width / mon.scale : 1440
    readonly property real monH: mon ? mon.height / mon.scale : 960
    readonly property var activeWs: Hyprland.focusedWorkspace

    // ---------- sizes ----------
    readonly property int stripTop: 20
    readonly property int bandH: stripTop + cardH + 34     // workspace band (background + line below)
    readonly property int cardH: Math.min(96, Math.floor(((width - 120 - (Workspaces.count - 1) * cardGap) / Workspaces.count) * monH / monW))
    readonly property real cardW: cardH * monW / monH
    readonly property int cardGap: 16
    // window area in the middle
    readonly property rect area: Qt.rect(80, bandH + 40, width - 160, height - bandH - 40 - 56)

    property int current: 0                  // window picked with the keyboard
    property bool keyboard: false            // highlight the pick only after the arrows were used
    property var dragged: null               // { toplevel, icon, title } while dragging
    property var chosen: null                // clicked window: on close it goes back to its place above the others
    property point dragPos

    // window layer on screen: 0 covered, 1 visible, 2 floating
    function layer(t) {
        if (t.lastIpcObject?.floating) return 2;
        return (Ui.overviewGeo[addr(t)]?.visible ?? true) ? 1 : 0;
    }
    // window capture taken on opening ("" if missing)
    function shot(t) {
        const id = Ui.overviewGeo[addr(t)]?.id;
        return id ? "file://" + Ui.overviewDir + "/" + id + ".png?" + Ui.overviewStamp : "";
    }
    function addr(t) { return (t.address.startsWith("0x") ? "" : "0x") + t.address; }
    // workspace change: first release the keyboard while still visible (on release Hyprland gives focus back
    // to the last active window and would jump to its workspace: it happens underneath, unseen),
    // then switch workspace under the overview and finally fade out
    property int pendingWs: 0
    function go(id) {
        if (id === Workspaces.activeId) { Ui.close(); return; }
        pendingWs = id;
        goLater.restart();
    }
    Timer { id: goLater; interval: 40; onTriggered: { Workspaces.go(win.pendingWs); Ui.close(); } }
    function focusWindow(t) { chosen = t; Hyprland.dispatch(`hl.dsp.focus({ window = "address:${addr(t)}" })`); Ui.close(); }
    function closeWindow(t) { Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${addr(t)}" })`); refresh.restart(); }
    function moveWindow(t, id) {
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${id}, follow = false, window = "address:${addr(t)}" })`);
        refresh.restart();
    }
    Timer { id: refresh; interval: 120; onTriggered: Hyprland.refreshToplevels() }

    function wsAt(p) {
        for (let i = 0; i < cards.count; i++) {
            const c = cards.itemAt(i);
            const q = c.mapFromItem(null, p.x, p.y);
            if (q.x >= 0 && q.y >= 0 && q.x < c.width && q.y < c.height) return i + 1;
        }
        return 0;
    }

    // real window position on screen (monitor-local coordinates)
    function real(t) {
        const o = Ui.overviewGeo[addr(t)] ?? t.lastIpcObject ?? {};
        const m = t.workspace?.monitor;
        return Qt.rect((o.at?.[0] ?? 0) - (m?.x ?? 0), (o.at?.[1] ?? 0) - (m?.y ?? 0), o.size?.[0] ?? 0, o.size?.[1] ?? 0);
    }

    // windows of the current workspace, in screen order (rows from the top, then from the left)
    readonly property var wins: (activeWs?.toplevels.values ?? [])
        .filter(t => real(t).width > 0)
        .slice().sort((a, b) => { const ra = real(a), rb = real(b); return (ra.y + ra.height / 2) - (rb.y + rb.height / 2) || ra.x - rb.x; })

    // grid: rows of equal height, with the row count that makes windows largest
    readonly property var layout: {
        const n = wins.length, W = area.width, H = area.height, gap = 28;
        if (!n) return [];
        const rs = wins.map(real);
        let best = null;
        for (let r = 1; r <= n; r++) {
            const per = Math.ceil(n / r);
            const rows = [];
            for (let i = 0; i < n; i += per) rows.push([...Array(Math.min(per, n - i)).keys()].map(k => i + k).sort((a, b) => rs[a].x - rs[b].x));
            let h = (H - gap * (rows.length - 1)) / rows.length;
            for (const row of rows) {
                const aspect = row.reduce((s, i) => s + rs[i].width / rs[i].height, 0);
                h = Math.min(h, (W - gap * (row.length - 1)) / aspect);
            }
            // never larger than they really are
            h = Math.min(h, Math.max(...rs.map(q => q.height)) * 0.85);
            if (!best || h > best.h) best = { h, rows };
        }
        const out = new Array(n);
        const totalH = best.rows.length * best.h + gap * (best.rows.length - 1);
        let y = area.y + (H - totalH) / 2;
        for (const row of best.rows) {
            const ws = row.map(i => best.h * rs[i].width / rs[i].height);
            let x = area.x + (W - ws.reduce((s, w) => s + w, 0) - gap * (row.length - 1)) / 2;
            row.forEach((i, k) => { out[i] = Qt.rect(x, y, ws[k], best.h); x += ws[k] + gap; });
            y += best.h + gap;
        }
        return out;
    }

    // ---------- background: blurred wallpaper + veil ----------
    Item {
        anchors.fill: parent
        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim.normal } }
        Image {
            anchors.fill: parent
            source: "file://" + Quickshell.env("HOME") + "/.cache/wallpaper/lock.jpg"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        Rectangle { anchors.fill: parent; color: Theme.c.shade; opacity: 0.45 }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: Ui.close() }
    }

    // ---------- workspace strip ----------
    Rectangle {
        width: parent.width; height: win.bandH
        y: win.open ? 0 : -height
        Behavior on y { NumberAnimation { duration: Theme.anim.normal; easing.type: Easing.OutCubic } }
        color: Qt.rgba(27 / 255, 32 / 255, 43 / 255, 0.72)     // Theme.c.frame, semi-transparent
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.c.ink4 }
        MouseArea { anchors.fill: parent }   // a click on the band doesn't close the overview
    }
    Row {
        id: strip
        anchors.horizontalCenter: parent.horizontalCenter
        y: win.open ? win.stripTop : -win.cardH - 40
        spacing: win.cardGap
        Behavior on y { NumberAnimation { duration: Theme.anim.normal; easing.type: Easing.OutCubic } }

        Repeater {
            id: cards
            model: Workspaces.count
            Item {
                id: card
                required property int index
                readonly property int wsId: index + 1
                readonly property var ws: Workspaces.byId(wsId)
                readonly property bool active: wsId === Workspaces.activeId
                readonly property bool dropTarget: win.dragged !== null && win.wsAt(win.dragPos) === wsId
                width: win.cardW
                height: win.cardH + 26

                // no ClippingRectangle: the software renderer doesn't draw it
                Item {
                    width: win.cardW; height: win.cardH
                    clip: true
                    scale: card.dropTarget ? 1.06 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.anim.fast } }

                    RRect { anchors.fill: parent; radius: 8; antialiasing: true; color: Theme.c.ink1 }
                    Image {
                        anchors.fill: parent; anchors.margins: 2
                        source: "file://" + Quickshell.env("HOME") + "/.local/state/wallpaper"
                        sourceSize.width: 320
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: 0.6
                    }
                    // workspace windows in miniature: capture, or icon if missing
                    Repeater {
                        // draw order: covered first, then visible, floating on top
                        model: (card.ws?.toplevels.values ?? []).slice().sort((a, b) => win.layer(a) - win.layer(b))
                        Item {
                            id: mini
                            required property var modelData
                            readonly property rect r: win.real(modelData)
                            readonly property real k: win.cardW / win.monW
                            x: r.x * k; y: r.y * k; width: r.width * k; height: r.height * k
                            visible: width > 0 && height > 0
                            clip: true
                            RRect { anchors.fill: parent; radius: 3; antialiasing: true; color: Theme.c.cell }
                            Image {
                                id: miniShot
                                anchors.fill: parent
                                source: win.shot(mini.modelData)
                                sourceSize.width: 240
                                cache: false
                                smooth: true
                                asynchronous: true
                            }
                            IconImage {
                                visible: miniShot.status !== Image.Ready
                                anchors.centerIn: parent
                                implicitSize: Math.min(22, parent.height * 0.6, parent.width * 0.6)
                                source: Workspaces.icon(mini.modelData.wayland?.appId ?? mini.modelData.lastIpcObject?.class ?? "")
                            }
                        }
                    }
                    RRect {
                        anchors.fill: parent; radius: 8; antialiasing: true
                        color: "transparent"
                        border.width: 2
                        border.color: card.dropTarget ? Theme.c.warm : card.active ? Theme.c.blue : cardArea.containsMouse ? Theme.c.ink5 : Theme.c.ink4
                    }
                    MouseArea {
                        id: cardArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.go(card.wsId)
                    }
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: win.cardH + 6
                    text: "Workspace " + card.wsId
                    font.pixelSize: Theme.font.small; font.bold: card.active
                    color: card.active ? Theme.c.blue : Theme.c.fg2
                }
            }
        }
    }

    // ---------- windows of the current workspace ----------
    Txt {
        visible: win.wins.length === 0
        anchors.centerIn: parent
        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim.normal } }
        text: "No windows"; color: Theme.c.muted; font.pixelSize: Theme.font.large
    }

    Repeater {
        model: win.wins
        Item {
            id: tile
            required property var modelData
            required property int index
            readonly property rect from: win.real(modelData)
            readonly property rect to: win.layout[index] ?? from
            readonly property rect at: (win.open || win.pendingWs) ? to : from
            readonly property bool hot: tileArea.containsMouse || (win.keyboard && index === win.current)
            readonly property string cls: modelData.wayland?.appId ?? modelData.lastIpcObject?.class ?? ""
            readonly property bool isDragged: win.dragged !== null && win.dragged.toplevel === modelData
            // covered by another window (e.g. under a maximized one) when the overview opened:
            // on close it vanishes at once instead of going back drawn above the one covering it
            readonly property bool covered: !(Ui.overviewGeo[win.addr(modelData)]?.visible ?? false)
            readonly property bool isChosen: win.chosen === modelData
            visible: win.open || isChosen || !covered
            z: isChosen ? 2 : covered ? 0 : 1
            x: at.x; y: at.y; width: at.width; height: at.height
            // when going to another workspace the windows fade out instead of going back
            opacity: isDragged ? 0.35 : (win.pendingWs && !win.open) ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }
            Behavior on x { NumberAnimation { duration: Theme.anim.slow - 100; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: Theme.anim.slow - 100; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Theme.anim.slow - 100; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: Theme.anim.slow - 100; easing.type: Easing.OutCubic } }

            Item {
                anchors.fill: parent
                clip: true
                RRect { anchors.fill: parent; radius: 6; antialiasing: true; color: Theme.c.cell }
                // window capture taken on opening (Ui.openOverview)
                Image {
                    id: thumb
                    readonly property bool hasContent: status === Image.Ready
                    anchors.fill: parent
                    source: win.shot(tile.modelData)
                    sourceSize.width: 900          // decode downscaled: captures are full resolution
                    cache: false
                    smooth: true
                    asynchronous: true
                }
                Column {
                    visible: !thumb.hasContent
                    anchors.centerIn: parent
                    spacing: 6
                    IconImage { anchors.horizontalCenter: parent.horizontalCenter; implicitSize: 48; source: Workspaces.icon(tile.cls) }
                }
            }
            // selection border
            RRect {
                anchors.fill: parent; anchors.margins: -3
                radius: 8; antialiasing: true
                color: "transparent"
                border.width: 1.5; border.color: Theme.c.violet
                opacity: tile.hot && win.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }
            }
            // icon + title below the window
            RRect {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: -16 }
                width: Math.min(label.implicitWidth + 44, Math.max(parent.width, 160)); height: 32; radius: 10; antialiasing: true
                color: Theme.c.panel
                opacity: win.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.anim.normal } }
                IconImage { id: appIcon; anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter } implicitSize: 18; source: Workspaces.icon(tile.cls) }
                Txt {
                    id: label
                    anchors { left: appIcon.right; leftMargin: 8; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    text: tile.modelData.title; elide: Text.ElideRight
                    font.pixelSize: Theme.font.small
                    color: tile.hot ? Theme.c.fg : Theme.c.fg2
                }
            }

            MouseArea {
                id: tileArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                cursorShape: win.dragged ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                property point start
                onEntered: win.current = tile.index
                onPressed: mouse => start = Qt.point(mouse.x, mouse.y)
                onPositionChanged: mouse => {
                    if (!pressed || !(pressedButtons & Qt.LeftButton)) return;
                    if (!win.dragged && Math.hypot(mouse.x - start.x, mouse.y - start.y) > 8)
                        win.dragged = { toplevel: tile.modelData, icon: Workspaces.icon(tile.cls), title: tile.modelData.title };
                    if (win.dragged) win.dragPos = mapToItem(null, mouse.x, mouse.y);
                }
                onReleased: mouse => {
                    if (mouse.button === Qt.MiddleButton) { win.closeWindow(tile.modelData); return; }
                    if (win.dragged) {
                        const id = win.wsAt(mapToItem(null, mouse.x, mouse.y));
                        if (id && id !== Workspaces.activeId) win.moveWindow(tile.modelData, id);
                        win.dragged = null;
                    } else win.focusWindow(tile.modelData);
                }
            }
        }
    }

    // dragged window: follows the mouse
    RRect {
        visible: win.dragged !== null
        x: win.dragPos.x - width / 2; y: win.dragPos.y - height / 2
        width: dragRow.implicitWidth + 20; height: 40; radius: 10; antialiasing: true
        color: Theme.c.panel
        border.width: 1; border.color: Theme.c.blue
        Row {
            id: dragRow
            anchors.centerIn: parent
            spacing: 8
            IconImage { anchors.verticalCenter: parent.verticalCenter; implicitSize: 20; source: win.dragged?.icon ?? "" }
            Txt { anchors.verticalCenter: parent.verticalCenter; text: win.dragged?.title ?? ""; width: Math.min(implicitWidth, 260); elide: Text.ElideRight }
        }
    }

    Item {
        focus: true
        Keys.onPressed: event => {
            const k = event.key, n = win.wins.length;
            if (k === Qt.Key_Escape) Ui.close();
            else if ((k === Qt.Key_Return || k === Qt.Key_Enter) && n) win.focusWindow(win.wins[Math.min(win.current, n - 1)]);
            else if (k === Qt.Key_Left || k === Qt.Key_Up) win.keyboard = true, win.current = Math.max(0, win.current - 1);
            else if (k === Qt.Key_Right || k === Qt.Key_Down || k === Qt.Key_Tab) win.keyboard = true, win.current = n ? (win.current + 1) % n : 0;
            else if (k >= Qt.Key_1 && k <= Qt.Key_9 && k - Qt.Key_0 <= Workspaces.count) win.go(k - Qt.Key_0);
            else return;
            event.accepted = true;
        }
    }
}
