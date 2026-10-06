pragma Singleton
// Battery (UPower) and power profile (power-profiles-daemon).
// On battery: a notification at Config.batteryWarning, a critical one at Config.batteryCritical
// (stays until dismissed, shows with do not disturb too), power saver at Config.batterySaver.
// Each one once per discharge: plugging in resets them and gives back the profile used before the saver.
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.config

Singleton {
    id: root
    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property bool present: dev?.isLaptopBattery ?? false
    readonly property int percent: Math.round((dev?.percentage ?? 0) * 100)
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
    readonly property bool plugged: !UPower.onBattery
    readonly property real watts: Math.abs(dev?.changeRate ?? 0)
    readonly property real health: dev?.healthPercentage ?? 0
    // seconds -> "1h 25m"
    readonly property string timeLeft: {
        const s = charging ? dev?.timeToFull : dev?.timeToEmpty;
        if (!s) return "";
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        return (h ? h + "h " : "") + m + "m" + (charging ? " to full" : " left");
    }

    readonly property int profile: PowerProfiles.profile
    readonly property string profileName: profile === PowerProfile.Performance ? "performance"
                                        : profile === PowerProfile.PowerSaver ? "power saver" : "balanced"
    // 0 power saver · 1 balanced · 2 performance
    function setProfile(i) { PowerProfiles.profile = [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance][i]; }
    // cycle order: balanced -> performance -> power saver
    function cycleProfile() {
        PowerProfiles.profile = profile === PowerProfile.Balanced ? PowerProfile.Performance
                              : profile === PowerProfile.Performance ? PowerProfile.PowerSaver : PowerProfile.Balanced;
    }

    // ---------- low battery ----------
    property int warned: 0              // 0 none · 1 warning sent · 2 critical sent
    property bool saverDone: false      // saver already handled in this discharge (not forced again if turned off)
    property bool saverByUs: false      // we turned it on: give back the previous profile when plugged in
    property int profileBefore: PowerProfile.Balanced

    onPercentChanged: check()
    onPluggedChanged: check()
    onPresentChanged: check()

    function notify(urgency, title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", urgency, "-i", "battery-caution", title, body]);
    }

    function check() {
        if (!present || percent <= 0) return;          // UPower not read yet
        if (plugged) {
            warned = 0;
            saverDone = false;
            if (saverByUs && profile === PowerProfile.PowerSaver) PowerProfiles.profile = profileBefore;
            saverByUs = false;
            return;
        }
        if (percent <= Config.batteryCritical && warned < 2) {
            warned = 2;
            notify("critical", "Battery critical: " + percent + "%", "Plug in the charger now");
        } else if (percent <= Config.batteryWarning && warned < 1) {
            warned = 1;
            notify("normal", "Battery low: " + percent + "%", timeLeft || "Plug in the charger soon");
        }
        if (percent <= Config.batterySaver && !saverDone) {
            saverDone = true;
            if (profile !== PowerProfile.PowerSaver) {
                const before = profileName;
                profileBefore = profile;
                saverByUs = true;
                PowerProfiles.profile = PowerProfile.PowerSaver;
                notify("low", "Power saver on", "Battery at " + percent + "%: back to " + before + " when plugged in");
            }
        }
    }
}
