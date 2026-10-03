// Shell lock screen (replaces hyprlock).
// Lock with `quickshell ipc call shell lock` (hypridle / SUPER+L go through loginctl lock-session).
// ext-session-lock is safe: if the shell dies while locked, the screen stays locked.
// Password checked by PAM with the same config as hyprlock (/etc/pam.d/login).
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.services

Scope {
    id: root

    // state shared by all screens (there is one password)
    property string buffer: ""
    property bool busy: false          // PAM is checking
    property bool unlocking: false     // exit animation
    property int fails: 0              // changes on every failure (triggers the shake)
    property string message: ""

    function submit() {
        if (busy || buffer === "") return;
        message = "";
        busy = true;
        pam.start();
    }
    function clear() { if (!busy) buffer = ""; }

    // every new lock starts clean. Done on Ui.locked (the request), not on the lock object's own
    // lockedChanged: after an unlock that signal was not always delivered on the next lock, so
    // `unlocking` stayed true and the lock showed only its background (content faded out).
    Connections {
        target: Ui
        function onLockedChanged() { if (Ui.locked) { root.unlocking = false; root.busy = false; root.buffer = ""; root.message = ""; } }
    }

    WlSessionLock {
        id: lock
        locked: Ui.locked

        WlSessionLockSurface {
            color: "#151923"
            LockView { anchors.fill: parent; ctx: root }
        }
    }

    PamContext {
        id: pam
        // the password is sent once, when PAM asks for it
        onResponseRequiredChanged: if (responseRequired) respond(root.buffer)
        onCompleted: result => {
            root.busy = false;
            if (result === PamResult.Success) {
                root.unlocking = true;
                unlockDelay.restart();
            } else {
                root.buffer = "";
                root.fails++;
                // after too many failures pam_faillock locks the account for a while: show its message
                root.message = pam.messageIsError && pam.message ? pam.message : "Wrong password";
            }
        }
        onError: {
            root.busy = false;
            root.buffer = "";
            root.fails++;
            root.message = "Authentication error";
        }
    }

    // let the fade finish, then really unlock
    Timer { id: unlockDelay; interval: 320; onTriggered: Ui.locked = false }
}
