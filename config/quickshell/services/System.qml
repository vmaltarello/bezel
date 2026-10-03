pragma Singleton
// CPU, RAM, swap, temperature and disks read from /proc and /sys.
// Always sampled every 3 s (a few tiny files) to keep the last 2 minutes of history,
// but values are published only while the desktop widgets are visible: covered = no redraws.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root
    readonly property bool seen: Ui.desktopSeen
    readonly property int histLength: 40          // 40 x 3 s = 2 minutes

    property int cpu: 0              // %
    property int mem: 0              // %
    property real memUsed: 0         // GiB
    property real memTotal: 0        // GiB
    property real swapUsed: 0        // GiB
    property int temp: 0             // °C
    property int uptime: 0           // seconds
    property int diskRoot: 0         // % used of /
    property int diskHome: 0         // % used of /home
    property var cpuHist: []         // last 2 minutes, %
    property var memHist: []

    // internal values, always up to date
    property var _prev: null
    property var _v: ({ cpu: 0, mem: 0, memUsed: 0, memTotal: 0, swapUsed: 0, temp: 0 })
    property var _cpuHist: []
    property var _memHist: []

    function _push(list, v) { list.push(v); if (list.length > histLength) list.shift(); }
    function publish() {
        if (!seen) return;
        cpu = _v.cpu; mem = _v.mem; memUsed = _v.memUsed; memTotal = _v.memTotal; swapUsed = _v.swapUsed; temp = _v.temp;
        cpuHist = _cpuHist.slice(); memHist = _memHist.slice();
    }
    onSeenChanged: if (seen) { publish(); up.reload(); disk.running = true; }

    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { stat.reload(); meminfo.reload(); if (tempFile.path) tempFile.reload(); if (root.seen) up.reload(); }
    }

    FileView {
        id: stat; path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
            if (root._prev) {
                const dt = total - root._prev.total;
                if (dt > 0) { root._v.cpu = Math.round(100 * (1 - (idle - root._prev.idle) / dt)); root._push(root._cpuHist, root._v.cpu); }
            }
            root._prev = { idle, total };
            root.publish();
        }
    }
    FileView {
        id: meminfo; path: "/proc/meminfo"
        onLoaded: {
            const v = k => Number((text().match(new RegExp("^" + k + ":\\s+(\\d+)", "m")) ?? [0, 0])[1]) / 1048576;
            const o = root._v;
            o.memTotal = v("MemTotal");
            o.memUsed = o.memTotal - v("MemAvailable");
            o.mem = o.memTotal > 0 ? Math.round(100 * o.memUsed / o.memTotal) : 0;
            o.swapUsed = v("SwapTotal") - v("SwapFree");
            root._push(root._memHist, o.mem);
        }
    }
    FileView { id: up; path: "/proc/uptime"; onLoaded: root.uptime = Math.floor(Number(text().split(" ")[0])) }
    // disk usage: when widgets become visible and every 10 minutes
    Timer { interval: 600000; running: true; repeat: true; onTriggered: disk.running = true }
    Process {
        id: disk
        running: true
        command: ["df", "--output=pcent", "/", "/home"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.split("\n").slice(1).map(l => Number(l.replace("%", "").trim()));
                root.diskRoot = v[0] || 0; root.diskHome = v[1] || 0;
            }
        }
    }
    // CPU sensor: hwmonN changes between boots, so look it up by driver name at startup
    FileView {
        id: tempFile
        onLoaded: root._v.temp = Math.round(Number(text()) / 1000)
    }
    Process {
        running: true
        command: ["sh", "-c", "for n in " + Config.tempSensors.join(" ") + "; do for d in /sys/class/hwmon/hwmon*; do "
                  + "[ \"$(cat $d/name 2>/dev/null)\" = $n ] && [ -r $d/temp1_input ] && { echo $d/temp1_input; exit; }; done; done"]
        stdout: StdioCollector { onStreamFinished: tempFile.path = text.trim() }
    }
}
