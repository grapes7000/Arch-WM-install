pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int percent: -1
    property bool charging: false
    property string timeRemaining: ""
    property bool available: false

    function parse(contents) {
        for (const line of contents.trim().split("\n")) {
            const sep = line.indexOf("=")
            if (sep <= 0) continue
            const key = line.slice(0, sep)
            const val = line.slice(sep + 1)
            if (key === "percent") {
                root.percent = Math.max(0, Math.min(100, Number(val)))
                root.available = true
            } else if (key === "charging")
                root.charging = val === "1"
            else if (key === "time")
                root.timeRemaining = val
        }
    }

    Process {
        id: pollProc
        command: [
            "sh", "-c",
            "bat=$(ls -1 /sys/class/power_supply/ 2>/dev/null | grep -i bat | head -1); "
            + "if [ -z \"$bat\" ]; then printf 'percent=-1\\n'; exit 0; fi; "
            + "base=/sys/class/power_supply/$bat; "
            + "cap=$(cat $base/capacity 2>/dev/null || echo -1); "
            + "st=$(cat $base/status 2>/dev/null || echo Unknown); "
            + "chrg=0; case \"$st\" in Charging|Full) chrg=1;; esac; "
            + "now=$(cat $base/energy_now 2>/dev/null || cat $base/charge_now 2>/dev/null || echo 0); "
            + "rate=$(cat $base/power_now 2>/dev/null || cat $base/current_now 2>/dev/null || echo 0); "
            + "t=''; if [ \"$rate\" -gt 0 ] 2>/dev/null; then "
            + "  h=$((now/rate)); m=$(((now*60/rate)%60)); t=\"${h}h ${m}m\"; fi; "
            + "printf 'percent=%s\\ncharging=%s\\ntime=%s\\n' \"$cap\" \"$chrg\" \"$t\""
        ]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!pollProc.running) pollProc.running = true }
    }
}
