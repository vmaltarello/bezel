pragma Singleton
// Caffeine: while active the screen doesn't lock or turn off and the system doesn't suspend.
// Toggled from the bar icon; the actual idle inhibitor lives in the bar (it needs a window).
import QtQuick
import Quickshell

Singleton {
    property bool active: false
    function toggle() { active = !active; }
}
