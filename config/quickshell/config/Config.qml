pragma Singleton
// Settings not related to the look.
import QtQuick
import Quickshell

Singleton {
    // locale for time and date: "" = system locale, or e.g. "it_IT"
    readonly property string locale: ""
    readonly property string timeFormat: "HH:mm"
    readonly property string dateFormat: "ddd dd MMM"

    // workspaces always shown, even when empty
    readonly property int persistentWorkspaces: 5

    // warning thresholds (percent / degrees)
    readonly property int cpuWarning: 70
    readonly property int cpuCritical: 90
    readonly property int memWarning: 75
    readonly property int memCritical: 90
    readonly property int tempWarning: 75
    readonly property int tempCritical: 85
    readonly property int batteryWarning: 25
    readonly property int batteryCritical: 12

    // CPU temperature: first hwmon whose driver name is in this list (AMD, Intel, ARM boards)
    readonly property var tempSensors: ["k10temp", "zenpower", "coretemp", "cpu_thermal"]


    // commands launched from the bar
    readonly property QtObject cmd: QtObject {
        readonly property string monitor: "kitty -1 --class kitty-float -e btop"
        readonly property string wifi: "kitty -1 --class kitty-float -e nmtui"
        readonly property string bluetooth: "kitty -1 --class kitty-float -e bluetui"
        readonly property string mixer: "hyprpwcenter"
    }
}
