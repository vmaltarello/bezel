pragma Singleton
// Do not disturb: while active, notifications are not shown (except critical ones).
// SUPER+N (quickshell ipc call shell dnd) or the bar icon.
import QtQuick
import Quickshell

Singleton {
    property bool active: false
    function toggle() { active = !active; }
}
