// Screenshot selection over the frozen monitor (services/Shot.qml).
// Area: drag a rectangle, captures on release · Window: click the highlighted window
// Screen (or Enter): full screen · Tab: area/window · Esc or right click: cancel.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "black"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-screenshot"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // physical pixels per logical pixel (from the image itself: no guessing the scale)
    readonly property real ratio: shot.implicitWidth > 0 ? shot.implicitWidth / width : 1
    // current selection in logical coordinates (w = 0: none)
    property rect sel: Qt.rect(0, 0, 0, 0)
    property bool dragging: false
    property point origin

    function px(v) { return Math.round(v * ratio); }
    function captureRect(r) {
        const x = Math.max(0, r.x), y = Math.max(0, r.y);
        const w = Math.min(width, r.x + r.width) - x, h = Math.min(height, r.y + r.height) - y;
        if (w < 2 || h < 2) return;
        Shot.capture(px(x), px(y), px(x + w) - px(x), px(y + h) - px(y));
    }
    function windowAt(x, y) {
        return Shot.windows.find(c => x >= c.x && x < c.x + c.w && y >= c.y && y < c.y + c.h) ?? null;
    }

    Image {
        id: shot
        anchors.fill: parent
        source: "file://" + Shot.frozen + "?" + Shot.stamp
        cache: false
        smooth: true
        mipmap: false
    }

    // dims everything except the selection
    Item {
        anchors.fill: parent
        readonly property color shade: Qt.rgba(10 / 255, 13 / 255, 20 / 255, 0.55)
        readonly property bool has: win.sel.width > 0
        Rectangle { color: parent.shade; x: 0; y: 0; width: parent.width; height: parent.has ? win.sel.y : parent.height }
        Rectangle { visible: parent.has; color: parent.shade; x: 0; y: win.sel.y; width: win.sel.x; height: win.sel.height }
        Rectangle { visible: parent.has; color: parent.shade; x: win.sel.x + win.sel.width; y: win.sel.y; width: parent.width - x; height: win.sel.height }
        Rectangle { visible: parent.has; color: parent.shade; x: 0; y: win.sel.y + win.sel.height; width: parent.width; height: parent.height - y }
    }

    // selection border + size in pixels
    Rectangle {
        visible: win.sel.width > 0
        x: win.sel.x - 2; y: win.sel.y - 2
        width: win.sel.width + 4; height: win.sel.height + 4
        color: "transparent"
        border.width: 2; border.color: Theme.c.blue
    }
    RRect {
        visible: win.sel.width > 0
        readonly property bool below: win.sel.y + win.sel.height + height + 10 < win.height
        x: Math.min(win.width - width - 8, Math.max(8, win.sel.x))
        y: below ? win.sel.y + win.sel.height + 8 : Math.max(8, win.sel.y - height - 8)
        width: dims.implicitWidth + 16; height: 26; radius: 8; antialiasing: true
        color: Theme.c.panel
        Txt { id: dims; anchors.centerIn: parent; font.pixelSize: Theme.font.small; color: Theme.c.fg2; text: `${win.px(win.sel.width)} × ${win.px(win.sel.height)}` }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Shot.mode === "area" ? Qt.CrossCursor : Qt.PointingHandCursor
        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) { Shot.cancel(); return; }
            if (Shot.mode !== "area") return;
            win.origin = Qt.point(mouse.x, mouse.y);
            win.sel = Qt.rect(mouse.x, mouse.y, 0, 0);
            win.dragging = true;
        }
        onPositionChanged: mouse => {
            if (Shot.mode === "window") {
                const c = win.windowAt(mouse.x, mouse.y);
                win.sel = c ? Qt.rect(c.x, c.y, c.w, c.h) : Qt.rect(0, 0, 0, 0);
            } else if (win.dragging) {
                const x = Math.max(0, Math.min(mouse.x, win.width)), y = Math.max(0, Math.min(mouse.y, win.height));
                win.sel = Qt.rect(Math.min(x, win.origin.x), Math.min(y, win.origin.y), Math.abs(x - win.origin.x), Math.abs(y - win.origin.y));
            }
        }
        onReleased: mouse => {
            if (mouse.button !== Qt.LeftButton) return;
            if (Shot.mode === "window") { if (win.sel.width > 0) win.captureRect(win.sel); return; }
            win.dragging = false;
            if (win.sel.width >= 4 && win.sel.height >= 4) win.captureRect(win.sel);
            else win.sel = Qt.rect(0, 0, 0, 0);
        }
    }

    // ---------- bottom pill: mode, full screen, editor ----------
    component ModeButton: RRect {
        id: mb
        property string icon
        property string label
        property bool on: false
        signal clicked()
        width: row.implicitWidth + 24; height: 34; radius: 8; antialiasing: true
        color: on ? Theme.m.secondaryContainer : ma.containsMouse ? Theme.m.containerHigh : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8
            MIcon { anchors.verticalCenter: parent.verticalCenter; text: mb.icon; filled: mb.on; font.pixelSize: 20; color: mb.on ? Theme.m.primary : Theme.m.fgVariant }
            Txt { anchors.verticalCenter: parent.verticalCenter; text: mb.label; font.pixelSize: Theme.font.small + 1; color: mb.on ? Theme.m.fgSecondaryContainer : Theme.m.fgVariant }
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mb.clicked() }
    }

    RRect {
        id: pill
        visible: !win.dragging
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 36 }
        width: pillRow.implicitWidth + 16; height: 50; radius: Theme.size.radius; antialiasing: true
        color: Theme.c.panel
        border.width: 1; border.color: Theme.c.ink4
        // don't start a selection under the pill
        MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons }
        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 4
            ModeButton { icon: "crop"; label: "Area"; on: Shot.mode === "area"; onClicked: { Shot.mode = "area"; win.sel = Qt.rect(0, 0, 0, 0); } }
            ModeButton { icon: "web_asset"; label: "Window"; on: Shot.mode === "window"; onClicked: { Shot.mode = "window"; win.sel = Qt.rect(0, 0, 0, 0); } }
            ModeButton { icon: "fullscreen"; label: "Screen"; onClicked: Shot.capture(0, 0, 0, 0) }
            Rectangle { width: 1; height: 24; color: Theme.c.ink4; anchors.verticalCenter: parent.verticalCenter }
            Item { width: 8; height: 1 }
            Txt { anchors.verticalCenter: parent.verticalCenter; text: "Editor"; color: Theme.c.fg2 }
            Item { width: 4; height: 1 }
            Switch { anchors.verticalCenter: parent.verticalCenter; checked: Shot.editor; onToggled: Shot.editor = !Shot.editor }
            Item { width: 8; height: 1 }
        }
    }

    Item {
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) Shot.cancel();
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) Shot.capture(0, 0, 0, 0);
            else if (event.key === Qt.Key_Tab) { Shot.mode = Shot.mode === "area" ? "window" : "area"; win.sel = Qt.rect(0, 0, 0, 0); }
            else return;
            event.accepted = true;
        }
    }
}
