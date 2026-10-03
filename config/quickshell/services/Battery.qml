pragma Singleton
// Battery (UPower) and power profile (power-profiles-daemon).
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
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
}
