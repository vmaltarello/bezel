// Login screen for greetd. Same look as the lock screen.
// Not used from here: install.sh copies it to /etc/quickshell-greeter with the shell files it needs
// (the greeter runs as the "greeter" user and can't read your home).
// Outside greetd (preview) the fake password is "ok".
//@ pragma UseQApplication
//@ pragma Env QT_QUICK_BACKEND=software
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd
import "modules/lock"

ShellRoot {
    id: root

    // same interface as modules/lock/Lock.qml, plus the user list
    property var users: []
    property int userIndex: 0
    readonly property string user: users[userIndex] ?? ""
    property string buffer: ""
    property bool busy: false
    property bool unlocking: false
    property int fails: 0
    property string message: ""
    readonly property bool preview: !Greetd.available

    function cycleUser(d) { if (!busy) { userIndex = (userIndex + d + users.length) % users.length; buffer = ""; message = ""; } }
    function clear() { if (!busy) buffer = ""; }
    function submit() {
        if (busy || buffer === "" || user === "") return;
        busy = true; message = "";
        if (preview) fakeAuth.restart();
        else Greetd.createSession(user);
    }
    function fail(msg) {
        busy = false; buffer = ""; fails++;
        message = msg || "Wrong password";
    }
    function launch() {
        unlocking = true;
        launchDelay.restart();
    }

    // real users: uid 1000-59999 with a login shell
    FileView {
        path: "/etc/passwd"
        onLoaded: {
            root.users = text().split("\n").map(l => l.split(":"))
                .filter(f => +f[2] >= 1000 && +f[2] < 60000 && !/nologin|false$/.test(f[6] ?? ""))
                .map(f => f[0]);
        }
    }

    Connections {
        target: Greetd
        enabled: !root.preview
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) Greetd.respond(root.buffer);
            else if (error) root.message = message;
        }
        function onAuthFailure(message) { root.fail(message === "" ? "" : message.replace(/\.$/, "")); }
        function onError(error) { root.fail(error); Greetd.cancelSession(); }
        function onReadyToLaunch() { root.launch(); }
    }

    Timer { id: fakeAuth; interval: 600; onTriggered: root.buffer === "ok" ? root.launch() : root.fail("") }
    // let the fade finish, then start Hyprland (and the greeter exits)
    Timer {
        id: launchDelay; interval: 320
        onTriggered: root.preview ? Qt.quit() : Greetd.launch(["start-hyprland"], [], true)
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-greeter"
            color: "#151923"
            LockView {
                anchors.fill: parent
                ctx: root
                greeter: true
                // updated by wallpaper.sh (in preview: the session one)
                background: root.preview ? Quickshell.env("HOME") + "/.cache/wallpaper/lock.jpg" : "/var/lib/quickshell-greeter/background.jpg"
            }
        }
    }
}
