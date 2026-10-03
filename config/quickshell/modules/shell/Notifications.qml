// On-screen notifications: top right inside the frame, stacked, sliding in from the right.
// Bottom line = time left (pauses on hover). Click or ✕ = dismiss. No history.
import QtQuick
import QtQuick.Layouts
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
        spacing: 8

        Repeater {
            model: Notifs.list
            RRect {
                id: card
                required property var modelData
                readonly property var n: modelData
                readonly property bool critical: n.urgency === NotificationUrgency.Critical
                readonly property int timeout: Notifs.timeout(n)
                property real remaining: 1       // fraction of time left
                readonly property string icon: n.image || (n.appIcon ? Quickshell.iconPath(n.appIcon, true) : "")
                    || Workspaces.icon(n.desktopEntry || n.appName)

                width: stack.width
                height: content.implicitHeight + 24
                radius: Theme.size.radius
                color: Theme.c.frame
                border.width: 1
                border.color: critical ? Theme.m.error : Theme.m.outlineVariant
                clip: true

                // slide in from the right
                transform: Translate { id: slide; x: 60 }
                opacity: 0
                Component.onCompleted: enter.start()
                ParallelAnimation {
                    id: enter
                    NumberAnimation { target: slide; property: "x"; to: 0; duration: Theme.anim.normal; easing.type: Easing.OutCubic }
                    NumberAnimation { target: card; property: "opacity"; to: 1; duration: Theme.anim.normal }
                }

                // time on screen (pauses on hover)
                NumberAnimation on remaining {
                    id: countdown
                    running: card.timeout > 0
                    paused: hover.hovered
                    from: 1; to: 0
                    duration: Math.max(1, card.timeout)
                    // critical ones (timeout 0) never expire: a 0-duration animation would "finish" instantly
                    onFinished: if (card.timeout > 0) card.n.expire()
                }
                HoverHandler { id: hover }
                TapHandler { onTapped: card.n.dismiss() }

                RowLayout {
                    id: content
                    x: 14; y: 12
                    width: parent.width - 28
                    spacing: 12

                    // app icon (or notification image)
                    RRect {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 36; Layout.preferredHeight: 36
                        radius: 8
                        color: Theme.m.container
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: card.n.image ? 36 : 24
                            source: card.icon
                            visible: card.icon !== ""
                            asynchronous: true
                        }
                        MIcon { anchors.centerIn: parent; visible: card.icon === ""; text: "notifications"; filled: true; color: Theme.m.fgVariant }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        RowLayout {
                            Layout.fillWidth: true
                            Txt { text: card.n.appName || "Notification"; color: card.critical ? Theme.c.red : Theme.c.muted; font.pixelSize: Theme.font.small; elide: Text.ElideRight; Layout.fillWidth: true }
                            MIcon {
                                text: "close"; font.pixelSize: 16; color: closeArea.containsMouse ? Theme.m.fg : Theme.m.outline
                                opacity: hover.hovered ? 1 : 0
                                MouseArea { id: closeArea; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.n.dismiss() }
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

                // time left
                Rectangle {
                    visible: card.timeout > 0
                    anchors.bottom: parent.bottom
                    x: 16; height: 2; radius: 1
                    width: (parent.width - 32) * card.remaining
                    color: card.critical ? Theme.m.error : Theme.m.primary
                    opacity: 0.8
                }
            }
        }
    }
}
