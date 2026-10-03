// Launcher panel ("Spotlight" style): one search line with mode tabs, results below, key hints at the bottom.
// Lives inside Launcher.qml (window, open/close and logic); split out so it can be rendered in dev-harness.qml.
// Height follows the content: just the search line when there is nothing to show.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

Item {
    id: root
    required property var win
    readonly property int rowH: 46
    readonly property int maxRows: 6
    readonly property bool grid: win.kind === "wallpapers"
    readonly property int count: grid ? win.wallIdx.length : win.results.length
    readonly property int bodyH: grid ? 2 * 112 + 12
                               : count === 0 ? (win.query !== "" || win.mode !== "apps" ? 52 : 0)
                               : Math.min(count, maxRows) * rowH + 12

    width: 640
    implicitHeight: col.implicitHeight

    // the window clears the search when the mode changes or the launcher opens
    Connections {
        target: root.win
        function onModeChanged() { input.text = ""; }
        function onOpenChanged() { if (root.win.open) { input.text = ""; input.forceActiveFocus(); } }
    }
    Connections {
        target: Ui
        function onLauncherType(text) { input.text = text; input.cursorPosition = text.length; }
    }

    RRect {
        anchors.fill: parent
        radius: Theme.size.radius; antialiasing: true
        color: Theme.c.frame
        border.width: 1; border.color: Theme.m.outlineVariant
    }

    Column {
        id: col
        width: parent.width

        // ---------- search line ----------
        Item {
            width: parent.width; height: 58
            // shell-like prompt: ❯ search · = calc · $ command
            Txt {
                id: prompt
                x: 20; anchors.verticalCenter: parent.verticalCenter
                text: win.kind === "calc" ? "=" : win.kind === "cmd" ? "$" : "❯"
                color: Theme.m.primary; font.pixelSize: 22; font.bold: true
            }
            TextInput {
                id: input
                anchors { left: prompt.right; leftMargin: 14; right: tabs.left; rightMargin: 14; verticalCenter: parent.verticalCenter }
                color: Theme.m.fg
                font.family: Theme.font.family; font.pixelSize: 19
                selectionColor: Theme.m.primary; selectedTextColor: Theme.m.fgPrimary
                focus: win.open
                clip: true
                onTextChanged: win.query = text
                Txt {
                    visible: input.text === ""
                    color: Theme.m.outline; font.pixelSize: 19
                    text: ({ apps: "Search apps", clipboard: "Search clipboard", wallpapers: "Search wallpapers", keys: "Search shortcuts" })[win.mode]
                }
                Keys.onPressed: event => {
                    const shift = event.modifiers & Qt.ShiftModifier;
                    if (event.key === Qt.Key_Escape) Ui.close();
                    else if (event.key === Qt.Key_Down) win.move(root.grid ? 4 : 1);
                    else if (event.key === Qt.Key_Up) win.move(root.grid ? -4 : -1);
                    else if (root.grid && event.key === Qt.Key_Right) win.move(1);
                    else if (root.grid && event.key === Qt.Key_Left) win.move(-1);
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) win.activate(root.grid ? win.wallIdx[win.current] : win.current, shift);
                    else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                        const i = win.modes.findIndex(m => m[0] === win.mode);
                        Ui.launcherMode = win.modes[(i + (event.key === Qt.Key_Backtab ? win.modes.length - 1 : 1)) % win.modes.length][0];
                    }
                    else if (event.key === Qt.Key_Delete && shift && win.kind === "clipboard" && win.results[win.current]) Clip.remove(win.results[win.current].line);
                    else return;
                    event.accepted = true;
                }
            }
            // modes as text tabs (Tab cycles); the active one has an amber underline
            Row {
                id: tabs
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 14
                Repeater {
                    model: win.modes
                    Item {
                        id: tab
                        required property var modelData
                        readonly property bool on: win.mode === modelData[0] && win.kind === win.mode
                        width: tl.implicitWidth; height: 26
                        Txt {
                            id: tl
                            anchors.centerIn: parent
                            text: ({ apps: "apps", clipboard: "clip", wallpapers: "walls", keys: "keys" })[tab.modelData[0]]
                            font.pixelSize: Theme.font.small; font.bold: tab.on
                            color: tab.on ? Theme.m.primary : tabArea.containsMouse ? Theme.m.fg : Theme.m.outline
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: Theme.m.primary; visible: tab.on }
                        MouseArea { id: tabArea; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Ui.launcherMode = tab.modelData[0]; input.forceActiveFocus(); } }
                    }
                }
            }
        }

        Rectangle { visible: root.bodyH > 0; width: parent.width; height: 1; color: Theme.m.outlineVariant }

        // ---------- results ----------
        Item {
            width: parent.width; height: root.bodyH
            visible: height > 0

            ListView {
                id: list
                visible: !root.grid
                anchors { fill: parent; margins: 6 }
                clip: true
                model: win.results
                currentIndex: win.current
                highlightMoveDuration: 0
                boundsBehavior: Flickable.StopAtBounds
                // delegates use plain Rectangles: with the software renderer the view's clip does not
                // apply to Shape-based RRects, which would be drawn outside the list while scrolling
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === win.current
                    width: list.width; height: root.rowH; radius: 6
                    color: sel ? Theme.m.secondaryContainer : rowArea.containsMouse ? Theme.m.container : "transparent"
                    // selected: amber bar on the left, like a cursor line
                    Rectangle { visible: row.sel; x: 0; width: 3; height: parent.height - 16; anchors.verticalCenter: parent.verticalCenter; color: Theme.m.primary }
                    Item {
                        id: ico
                        x: 12; width: 28; height: 28; anchors.verticalCenter: parent.verticalCenter
                        IconImage { anchors.fill: parent; source: row.modelData.icon ?? ""; visible: !!row.modelData.icon; asynchronous: true }
                        MIcon { anchors.centerIn: parent; visible: !row.modelData.icon; text: row.modelData.sym ?? ""; filled: row.sel; color: row.sel ? Theme.m.primary : Theme.m.fgVariant; font.pixelSize: 22 }
                    }
                    Txt {
                        id: ttl
                        anchors { left: ico.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        width: Math.min(implicitWidth, parent.width - ico.width - 140)
                        text: row.modelData.title; elide: Text.ElideRight
                        font.pixelSize: Theme.font.small + 2; font.bold: row.sel
                        color: row.sel ? Theme.m.fgSecondaryContainer : Theme.m.fg
                    }
                    // subtitle on the same line, dimmer (Spotlight-like)
                    Txt {
                        anchors { left: ttl.right; leftMargin: 10; right: hint.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        text: row.modelData.sub; elide: Text.ElideRight
                        color: Theme.m.outline; font.pixelSize: Theme.font.small
                    }
                    Txt { id: hint; anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter } text: row.sel ? "↵" : ""; color: Theme.m.primary }
                    MouseArea {
                        id: rowArea
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: win.activate(row.index, false)
                    }
                }
                Txt {
                    anchors.centerIn: parent
                    visible: win.results.length === 0
                    text: win.mode === "clipboard" && win.query === "" ? "clipboard is empty" : "no results"
                    color: Theme.m.outline
                }
            }

            // wallpaper grid
            GridView {
                id: gridView
                visible: root.grid
                anchors { fill: parent; margins: 6 }
                clip: true
                cellWidth: width / 4; cellHeight: 112
                model: root.grid ? win.wallIdx : []
                currentIndex: win.current
                boundsBehavior: Flickable.StopAtBounds
                delegate: Item {
                    id: cellW
                    required property int modelData
                    required property int index
                    readonly property bool sel: index === win.current
                    width: gridView.cellWidth; height: gridView.cellHeight
                    Rectangle {
                        anchors { fill: parent; margins: 4 }
                        radius: 4
                        color: Theme.m.container
                        border.width: cellW.sel ? 2 : 0; border.color: Theme.m.primary
                        Image {
                            anchors { fill: parent; margins: cellW.sel ? 4 : 0 }
                            source: win.walls ? win.walls.get(cellW.modelData, "fileUrl") : ""
                            sourceSize.width: 260; sourceSize.height: 160
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.activate(cellW.modelData, false) }
                    }
                }
            }
        }

        // ---------- key hints ----------
        Rectangle { visible: root.bodyH > 0; width: parent.width; height: 1; color: Theme.m.outlineVariant }
        Item {
            visible: root.bodyH > 0
            width: parent.width; height: 30
            Txt {
                x: 16; anchors.verticalCenter: parent.verticalCenter
                text: win.mode === "clipboard" ? "↵ copy   ⇧del remove   tab mode   esc close"
                    : win.kind === "cmd" ? "↵ run   ⇧↵ in terminal   esc close"
                    : "↵ open   = calc   > command   tab mode   esc close"
                color: Theme.m.outline; font.pixelSize: 11
            }
            Txt {
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                text: root.count + (root.count === 1 ? " result" : " results")
                color: Theme.m.outline; font.pixelSize: 11
            }
        }
    }
}
