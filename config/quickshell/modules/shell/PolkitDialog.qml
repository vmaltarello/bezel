// Password prompt for polkit (apps asking admin rights): dimmed screen + a card in the lock screen style
// (code-comment title, one prompt line with a square per character). Enter = authenticate, Esc = cancel.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: win
    readonly property var flow: Polkit.flow
    readonly property bool busy: flow && !flow.isResponseRequired && !flow.isCompleted
    property bool failedRecently: false

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-polkit"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property bool ready: false
    Timer { running: true; interval: 16; onTriggered: win.ready = true }

    function submit() {
        if (!flow || !flow.isResponseRequired) return;
        flow.submit(input.text);
        input.text = "";
    }
    function cancel() { if (flow) flow.cancelAuthenticationRequest(); }

    Rectangle {
        anchors.fill: parent
        color: Theme.c.shade
        opacity: win.ready ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim.normal } }
        MouseArea { anchors.fill: parent; onClicked: input.forceActiveFocus() }
    }

    RRect {
        id: card
        anchors.centerIn: parent
        anchors.verticalCenterOffset: win.ready ? 0 : 16
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: Theme.anim.normal; easing.type: Easing.OutCubic } }
        width: 460
        height: body.implicitHeight + 2 * 26
        radius: Theme.size.radius
        color: Theme.m.barGlass
        opacity: win.ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim.normal } }

        property real shake: 0
        transform: Translate { x: card.shake }

        Column {
            id: body
            anchors { fill: parent; margins: 26 }
            spacing: 0

            Row {
                spacing: 10
                MIcon { anchors.verticalCenter: parent.verticalCenter; text: "shield_lock"; filled: true; color: Theme.m.primary; font.pixelSize: 20 }
                Txt { text: "// authentication required"; color: Theme.m.outline; font.pixelSize: Theme.font.normal }
            }
            Item { width: 1; height: 16 }
            Txt {
                width: parent.width
                text: win.flow?.message ?? ""
                wrapMode: Text.Wrap
                color: Theme.m.fg
                font.pixelSize: Theme.font.large
            }
            Item { width: 1; height: 6 }
            Txt {
                width: parent.width
                text: win.flow?.actionId ?? ""
                elide: Text.ElideMiddle
                color: Theme.m.outlineVariant
                font.pixelSize: Theme.font.small
            }
            Item { width: 1; height: 26 }

            // prompt line, underlined (squares for a password, plain text when the prompt is not secret)
            Item {
                id: field
                width: parent.width; height: 40
                readonly property bool secret: !(win.flow?.responseVisible ?? false)
                readonly property color lineColor: win.failedRecently ? Theme.m.error
                                                 : win.busy ? Theme.m.fgSecondaryContainer
                                                 : input.text.length ? Theme.m.primary : Theme.m.outlineVariant

                Txt {
                    id: prompt
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "❯"; font.pixelSize: 20; font.bold: true
                    color: win.failedRecently ? Theme.m.error : Theme.m.primary
                }
                Txt {
                    anchors { left: prompt.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    visible: input.text.length === 0
                    text: win.busy ? "checking…" : (win.flow?.inputPrompt ?? "").replace(/:\s*$/, "").toLowerCase() || "password"
                    color: Theme.m.outline
                    font.pixelSize: Theme.font.normal
                }
                Txt {
                    anchors { left: prompt.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    visible: !field.secret
                    text: input.text
                    font.pixelSize: Theme.font.normal
                }
                // fixed squares that switch on one by one (see LockView: a changing model would blink)
                Row {
                    anchors { left: prompt.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    visible: field.secret
                    spacing: 6
                    opacity: win.busy ? 0.5 : 1
                    Repeater {
                        model: 20
                        Rectangle {
                            required property int index
                            readonly property bool on: index < input.text.length
                            visible: on || scale > 0
                            width: 8; height: 8; radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.m.fg
                            scale: on ? 1 : 0
                            Behavior on scale { NumberAnimation { duration: Theme.anim.fast; easing.type: Easing.OutBack } }
                        }
                    }
                }
                Txt {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: "↵"; color: input.text.length ? Theme.m.primary : Theme.m.outlineVariant
                    font.pixelSize: Theme.font.large
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 2
                    color: field.lineColor
                    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
                }

                TextInput {
                    id: input
                    anchors.fill: parent
                    opacity: 0                        // the squares (or the plain Txt) stand for the text
                    focus: true
                    echoMode: field.secret ? TextInput.Password : TextInput.Normal
                    readOnly: win.busy
                    Component.onCompleted: forceActiveFocus()
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { win.submit(); event.accepted = true; }
                        else if (event.key === Qt.Key_Escape) { win.cancel(); event.accepted = true; }
                        else if (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier)) { input.text = ""; event.accepted = true; }
                    }
                }
            }
            Item { width: 1; height: 10 }
            // error / info from polkit, otherwise the key hints
            Txt {
                width: parent.width
                readonly property string extra: win.flow?.supplementaryMessage ?? ""
                text: win.failedRecently && !extra ? "error: authentication failed"
                    : extra ? (win.flow.supplementaryIsError ? "error: " : "") + extra.toLowerCase()
                    : "esc cancel · enter authenticate"
                color: win.failedRecently || (extra && win.flow.supplementaryIsError) ? Theme.m.error : Theme.m.outline
                elide: Text.ElideRight
                font.pixelSize: Theme.font.small
            }
        }

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: card; property: "shake"; to: -12; duration: 50 }
            NumberAnimation { target: card; property: "shake"; to: 10; duration: 70 }
            NumberAnimation { target: card; property: "shake"; to: -6; duration: 70 }
            NumberAnimation { target: card; property: "shake"; to: 3; duration: 60 }
            NumberAnimation { target: card; property: "shake"; to: 0; duration: 50 }
        }
    }

    Connections {
        target: win.flow
        function onAuthenticationFailed() { shakeAnim.restart(); win.failedRecently = true; failTimer.restart(); input.forceActiveFocus(); }
    }
    Timer { id: failTimer; interval: 1600; onTriggered: win.failedRecently = false }
}
