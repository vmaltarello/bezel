// On-screen notifications: top right inside the frame, stacked, sliding in from the right.
// Card lighter than the windows, no border; critical ones: a red stripe on the left.
// In: the card opens its room (others slide down) while it slides in from the right with a light spring.
// Out: it slides back out fading, then its room closes (others slide up); only then it's dismissed.
// Bottom line = time left (pauses on hover). Click or ✕ = dismiss. No history.
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: win
    readonly property int w: 380
    anchors { top: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    margins.top: Theme.size.frame + 10
    margins.right: Theme.size.frame + 10
    implicitWidth: w + 20          // room for sliding in from the right
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    mask: Region { item: stack }

    Column {
        id: stack
        x: 20
        width: win.w
        spacing: 0         // the gap is inside each card's room, so it closes along with it

        Repeater {
            model: Notifs.list
            Item {
                id: card
                required property var modelData
                readonly property var n: modelData
                readonly property bool critical: n.urgency === NotificationUrgency.Critical
                readonly property int timeout: Notifs.timeout(n)
                property real remaining: 1       // fraction of time left
                readonly property string icon: n.image || (n.appIcon ? Quickshell.iconPath(n.appIcon, true) : "")
                    || Workspaces.icon(n.desktopEntry || n.appName)

                readonly property real fullH: content.implicitHeight + 28
                property real room: 0            // 0..1: share of its height (+ gap) taken in the column
                property bool leaving: false
                width: stack.width
                height: (fullH + 8) * room

                // solid like the bar and panels (see-through text over the desktop widgets was unreadable),
                // with the 45° cut of every free-standing element
                Cut {
                    width: parent.width; height: card.fullH
                    cut: Theme.size.cut + 3
                    color: Theme.m.container
                }
                // critical: red stripe on the left
                Rectangle {
                    visible: card.critical
                    x: 6; y: 14; width: 3; height: card.fullH - 28; radius: 1.5
                    color: Theme.m.error
                }

                transform: Translate { id: slide; x: 90 }
                opacity: 0
                Component.onCompleted: enter.start()
                ParallelAnimation {
                    id: enter
                    NumberAnimation { target: card; property: "room"; to: 1; duration: Theme.anim.normal; easing.type: Easing.OutCubic }
                    NumberAnimation { target: slide; property: "x"; to: 0; duration: Theme.anim.slow; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                    NumberAnimation { target: card; property: "opacity"; to: 1; duration: Theme.anim.normal; easing.type: Easing.OutCubic }
                }
                // dismiss = clicked/closed by the user, otherwise expired
                function close(dismiss) {
                    if (leaving) return;
                    leaving = true;
                    enter.stop();
                    countdown.stop();
                    exit.dismiss = dismiss;
                    exit.start();
                }
                SequentialAnimation {
                    id: exit
                    property bool dismiss
                    ParallelAnimation {
                        NumberAnimation { target: slide; property: "x"; to: 90; duration: Theme.anim.normal; easing.type: Easing.InCubic }
                        NumberAnimation { target: card; property: "opacity"; to: 0; duration: Theme.anim.normal; easing.type: Easing.InCubic }
                    }
                    NumberAnimation { target: card; property: "room"; to: 0; duration: Theme.anim.normal; easing.type: Easing.InOutCubic }
                    ScriptAction { script: exit.dismiss ? card.n.dismiss() : card.n.expire() }
                }

                // time on screen (pauses on hover)
                NumberAnimation on remaining {
                    id: countdown
                    running: card.timeout > 0
                    paused: running && hover.hovered      // pausing a stopped animation only logs warnings
                    from: 1; to: 0
                    duration: Math.max(1, card.timeout)
                    // critical ones (timeout 0) never expire: a 0-duration animation would "finish" instantly
                    onFinished: if (card.timeout > 0 && !card.leaving) card.close(false)
                }
                HoverHandler { id: hover }
                TapHandler { onTapped: card.close(true) }

                RowLayout {
                    id: content
                    x: 14; y: 13
                    width: parent.width - x - 14
                    spacing: 12

                    // icon or image, bare (no box), vertically centered: corners rounded so covers and avatars look tidy
                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 40; implicitHeight: 40
                        Image {
                            visible: card.icon !== ""
                            anchors.centerIn: parent
                            width: 40; height: 40
                            sourceSize: Qt.size(width, height)
                            fillMode: Image.PreserveAspectCrop      // wide images (screenshots, covers) cropped square
                            source: card.icon
                            asynchronous: true
                        }
                        // covers the image corners with the card color (the software renderer can't clip round)
                        Shape {
                            visible: card.icon !== ""
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                fillColor: Theme.m.container
                                strokeColor: "transparent"
                                fillRule: ShapePath.OddEvenFill
                                PathSvg { path: "M-1,-1 H41 V41 H-1 Z M8,0 H32 A8,8 0 0 1 40,8 V32 A8,8 0 0 1 32,40 H8 A8,8 0 0 1 0,32 V8 A8,8 0 0 1 8,0 Z" }
                            }
                        }
                        MIcon {
                            anchors.centerIn: parent; visible: card.icon === ""
                            text: "notifications"; filled: true
                            color: Theme.m.fgVariant
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        RowLayout {
                            Layout.fillWidth: true
                            Txt { text: card.n.appName || "Notification"; color: Theme.c.muted; font.pixelSize: Theme.font.small; elide: Text.ElideRight; Layout.fillWidth: true }
                            MIcon {
                                text: "close"; font.pixelSize: 16; color: closeArea.containsMouse ? Theme.m.fg : Theme.m.outline
                                opacity: hover.hovered ? 1 : 0
                                MouseArea { id: closeArea; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.close(true) }
                            }
                        }
                        Txt { text: card.n.summary; font.bold: true; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; Layout.fillWidth: true; visible: text !== "" }
                        Txt {
                            text: card.n.body; visible: text !== ""
                            textFormat: Text.StyledText
                            color: Theme.c.fg2; font.pixelSize: Theme.font.small
                            wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        // action buttons
                        Flow {
                            Layout.fillWidth: true; Layout.topMargin: 4
                            visible: card.n.actions.length > 0
                            spacing: 6
                            Repeater {
                                model: card.n.actions
                                RRect {
                                    required property var modelData
                                    width: actTxt.implicitWidth + 24; height: 28; radius: 6
                                    color: actArea.containsMouse ? Theme.m.primary : Theme.m.containerHigh
                                    Txt { id: actTxt; anchors.centerIn: parent; text: parent.modelData.text; font.pixelSize: Theme.font.small; color: actArea.containsMouse ? Theme.m.fgPrimary : Theme.m.fg }
                                    MouseArea { id: actArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.invoke() }
                                }
                            }
                        }
                    }
                }

                // time left: thin line inside the card, clear of the rounded corners
                Rectangle {
                    visible: card.timeout > 0
                    x: Theme.size.radius; y: card.fullH - 6
                    width: (parent.width - 2 * Theme.size.radius) * card.remaining; height: 2; radius: 1
                    color: Theme.m.primary; opacity: 0.55
                }
            }
        }
    }
}
