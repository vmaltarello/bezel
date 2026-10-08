// Lock screen look (one per screen). `ctx` = Lock.qml (or a fake state for previews).
// Also used by the login screen (greeter/): with `greeter: true` it shows welcome, user switch and power buttons.
// Design "B, developer": giant monospace clock on the left (hours filled, minutes as amber outline),
// a narrow column on the right with a code-comment greeting, the date and a one-line password prompt.
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.components

Item {
    id: root
    required property var ctx
    property bool greeter: false
    property string background: Quickshell.env("HOME") + "/.cache/wallpaper/lock.jpg"
    // user: the session one, or the one picked in the greeter
    readonly property string user: ctx.user ?? Quickshell.env("USER")
    readonly property bool manyUsers: (ctx.users?.length ?? 0) > 1

    readonly property int hour: Time.now.getHours()
    readonly property string greeting: hour < 5 ? "still up" : hour < 12 ? "good morning"
                                     : hour < 18 ? "good afternoon" : "good evening"
    property bool caps: false
    property bool failedRecently: false

    readonly property int big: Math.max(1, Math.round(height * 0.36)) // clock digit size
    readonly property string hh: Time.time.split(":")[0]
    readonly property string mm: Time.time.split(":")[1]

    // ---- background: blurred wallpaper (made by wallpaper.sh), darker on the left where the clock is ----
    Image {
        anchors.fill: parent
        source: "file://" + root.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: false
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(5 / 255, 8 / 255, 10 / 255, 0.82) }
            GradientStop { position: 0.6; color: Qt.rgba(5 / 255, 8 / 255, 10 / 255, 0.55) }
            GradientStop { position: 1.0; color: Qt.rgba(5 / 255, 8 / 255, 10 / 255, 0.70) }
        }
    }

    // everything fades in and out
    Item {
        id: content
        anchors.fill: parent
        opacity: 0
        states: State {
            name: "in"; when: shown.done && !root.ctx.unlocking
            PropertyChanges { content.opacity: 1; clockShift.x: 0 }
        }
        transitions: Transition {
            NumberAnimation { properties: "opacity,x"; duration: Theme.anim.slow; easing.type: Easing.OutCubic }
        }
        Timer { id: shown; property bool done: false; interval: 30; running: true; onTriggered: done = true }

        // ---- left: the clock ----
        Column {
            id: clock
            anchors { left: parent.left; leftMargin: root.width * 0.07; verticalCenter: parent.verticalCenter }
            transform: Translate { id: clockShift; x: -root.width * 0.03 }     // slides in from the left
            spacing: -root.big * 0.18

            Txt {
                text: root.hh
                font.pixelSize: root.big
                font.weight: Font.ExtraBold
                font.letterSpacing: -root.big * 0.04
                color: Theme.m.fg
                renderType: Text.QtRendering
            }
            // minutes: outline only (stroked text path)
            Item {
                width: mmMetrics.width; height: mmMetrics.height
                TextMetrics { id: mmMetrics; font: mmShape.textFont; text: root.mm }
                Shape {
                    id: mmShape
                    readonly property font textFont: Qt.font({ family: Theme.font.family, pixelSize: root.big, weight: Font.ExtraBold, letterSpacing: -root.big * 0.04 })
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Theme.m.primary
                        strokeWidth: Math.max(2, root.big / 90)
                        fillColor: "transparent"
                        joinStyle: ShapePath.RoundJoin
                        PathText { x: 0; y: 0; font: mmShape.textFont; text: root.mm }
                    }
                }
            }
        }

        // ---- right column ----
        Column {
            id: side
            anchors { right: parent.right; rightMargin: root.width * 0.08; verticalCenter: parent.verticalCenter; verticalCenterOffset: root.big * 0.18 }
            width: Math.min(400, root.width * 0.3)
            spacing: 0

            // greeting as a code comment (greeter with several users: ‹ name › to switch)
            Row {
                spacing: 8
                Txt { text: "// " + (root.greeter ? "welcome" : root.greeting) + ","; color: Theme.m.outline; font.pixelSize: Theme.font.normal }
                MIcon {
                    visible: root.manyUsers; anchors.verticalCenter: parent.verticalCenter
                    text: "chevron_left"; color: Theme.m.outline; font.pixelSize: 18
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.ctx.cycleUser(-1) }
                }
                Txt { text: root.user; color: Theme.m.primary; font.pixelSize: Theme.font.normal; font.bold: true }
                MIcon {
                    visible: root.manyUsers; anchors.verticalCenter: parent.verticalCenter
                    text: "chevron_right"; color: Theme.m.outline; font.pixelSize: 18
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.ctx.cycleUser(1) }
                }
            }
            Item { width: 1; height: 14 }
            Txt {
                text: Time.loc.toString(Time.now, "dddd")
                font.pixelSize: 40; font.bold: true
                font.capitalization: Font.Capitalize
                color: Theme.m.fg
            }
            Txt {
                text: Time.loc.toString(Time.now, "d MMMM yyyy")
                font.pixelSize: Theme.font.large + 3
                color: Theme.m.fgVariant
            }
            Item { width: 1; height: 44 }

            // password: one prompt line, underlined
            Item {
                id: field
                width: parent.width; height: 46
                property real shake: 0
                transform: Translate { x: field.shake }
                readonly property color lineColor: root.failedRecently ? Theme.m.error
                                                 : root.ctx.busy ? Theme.m.fgSecondaryContainer
                                                 : input.text.length ? Theme.m.primary : Theme.m.outlineVariant

                Txt {
                    id: prompt
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "❯"; font.pixelSize: 22; font.bold: true
                    color: root.failedRecently ? Theme.m.error : Theme.m.primary
                }
                Txt {
                    anchors { left: prompt.right; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    visible: input.text.length === 0
                    text: root.ctx.busy ? "checking…" : "password"
                    color: Theme.m.outline
                    font.pixelSize: Theme.font.large
                }
                // one square per character (max 20), then a block cursor
                Row {
                    anchors { left: prompt.right; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    opacity: root.ctx.busy ? 0.5 : 1
                    // fixed 20 squares that switch on one by one: a model that changes size would rebuild
                    // (and re-animate) every square on each key, making the whole field blink
                    Repeater {
                        model: 20
                        Rectangle {
                            required property int index
                            readonly property bool on: index < input.text.length
                            visible: on || scale > 0
                            width: 9; height: 9; radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.m.fg
                            scale: on ? 1 : 0
                            Behavior on scale { NumberAnimation { duration: Theme.anim.fast; easing.type: Easing.OutBack } }
                        }
                    }
                    Rectangle {
                        width: 10; height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.m.primary
                        visible: !root.ctx.busy
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite; running: !root.ctx.busy
                            NumberAnimation { to: 0; duration: 0 }
                            PauseAnimation { duration: 530 }
                            NumberAnimation { to: 1; duration: 0 }
                            PauseAnimation { duration: 530 }
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
                    opacity: 0                       // the real text is hidden: the squares stand for it
                    focus: true
                    echoMode: TextInput.Password
                    readOnly: root.ctx.busy
                    text: root.ctx.buffer
                    onTextChanged: if (root.ctx.buffer !== text) root.ctx.buffer = text
                    Component.onCompleted: forceActiveFocus()
                    Keys.onPressed: event => {
                        capsRead.running = true; capsLate.restart();
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.ctx.submit(); event.accepted = true; }
                        else if (event.key === Qt.Key_Escape
                                 || (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier))) { root.ctx.clear(); event.accepted = true; }
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: input.forceActiveFocus() }

                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: field; property: "shake"; to: -12; duration: 50 }
                    NumberAnimation { target: field; property: "shake"; to: 10; duration: 70 }
                    NumberAnimation { target: field; property: "shake"; to: -6; duration: 70 }
                    NumberAnimation { target: field; property: "shake"; to: 3; duration: 60 }
                    NumberAnimation { target: field; property: "shake"; to: 0; duration: 50 }
                }
            }
            Item { width: 1; height: 10 }
            // error or caps lock warning
            Txt {
                height: 20
                text: root.ctx.message !== "" ? "error: " + root.ctx.message.toLowerCase() : root.caps ? "warning: caps lock is on" : ""
                color: root.ctx.message !== "" ? Theme.m.error : Theme.m.warning
                font.pixelSize: Theme.font.small
            }
        }

        // ---- bottom line: user@host · battery · (greeter) power buttons ----
        Row {
            anchors { left: side.left; bottom: parent.bottom; bottomMargin: 34 }
            spacing: 18
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: root.user + "@" + host.text().trim()
                color: Theme.m.outline
                font.pixelSize: Theme.font.small
            }
            Txt {
                visible: Battery.present
                anchors.verticalCenter: parent.verticalCenter
                text: (Battery.charging ? "charging " : "bat ") + Battery.percent + "%"
                color: Battery.charging ? Theme.m.tertiary
                     : Battery.percent <= Config.batteryCritical ? Theme.m.error
                     : Battery.percent <= Config.batteryWarning ? Theme.m.warning : Theme.m.outline
                font.pixelSize: Theme.font.small
            }
            // greeter: suspend, reboot, shut down
            Repeater {
                model: root.greeter ? [
                    { icon: "bedtime", cmd: "suspend" },
                    { icon: "restart_alt", cmd: "reboot" },
                    { icon: "power_settings_new", cmd: "poweroff" },
                ] : []
                MIcon {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.icon; font.pixelSize: 20
                    color: pwArea.containsMouse ? (modelData.cmd === "poweroff" ? Theme.m.error : Theme.m.fg) : Theme.m.outline
                    MouseArea { id: pwArea; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["systemctl", parent.modelData.cmd]) }
                }
            }
        }
    }

    FileView { id: host; path: "/etc/hostname" }

    // caps lock: read the keyboard led when shown and on every key (again shortly after: the led lags the key)
    Process {
        id: capsRead
        running: true
        command: ["sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null | sort -r | head -1"]
        stdout: StdioCollector { onStreamFinished: root.caps = this.text.trim() === "1" }
    }
    Timer { id: capsLate; interval: 150; onTriggered: capsRead.running = true }

    Connections {
        target: root.ctx
        function onFailsChanged() { shakeAnim.restart(); root.failedRecently = true; failTimer.restart(); }
    }
    Timer { id: failTimer; interval: 1600; onTriggered: { root.failedRecently = false; } }
}
