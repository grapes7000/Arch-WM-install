pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpuPercent: 0
    property int memoryPercent: 0
    property int diskPercent: 0
    property string uptime: "--"
    property real temperature: 0
    property var topProcesses: []
    property string error: ""

    function clear() {
        cpuPercent = 0
        memoryPercent = 0
        diskPercent = 0
        uptime = "--"
        temperature = 0
        topProcesses = []
    }

    function parse(contents) {
        const values = ({})
        const processes = []
        for (const raw of contents.trim().split("\n")) {
            const separator = raw.indexOf("=")
            if (separator <= 0) continue
            const key = raw.slice(0, separator)
            const value = raw.slice(separator + 1)
            if (key === "process") {
                const fields = value.split("\t")
                if (fields.length === 4 && Number.isFinite(Number(fields[0]))) {
                    processes.push({ pid: Number(fields[0]), cpu: Number(fields[1]) || 0, memory: Number(fields[2]) || 0, name: fields[3] })
                }
            } else values[key] = value
        }
        const required = ["cpu", "memory", "disk", "uptime"]
        if (!required.every(key => values[key] !== undefined && values[key] !== "")) {
            clear()
            error = "Malformed system statistics"
            return false
        }
        const cpu = Number(values.cpu)
        const memory = Number(values.memory)
        const disk = Number(values.disk)
        if (![cpu, memory, disk].every(Number.isFinite)) {
            clear()
            error = "Invalid system statistics"
            return false
        }
        cpuPercent = Math.max(0, Math.min(100, Math.round(cpu)))
        memoryPercent = Math.max(0, Math.min(100, Math.round(memory)))
        diskPercent = Math.max(0, Math.min(100, Math.round(disk)))
        uptime = values.uptime
        temperature = Number.isFinite(Number(values.temperature)) ? Number(values.temperature) : 0
        topProcesses = processes.slice(0, 5)
        error = ""
        return true
    }

    function refresh() {
        if (statsProcess.running) return false
        statsProcess.running = true
        watchdog.restart()
        return true
    }

    Process {
        id: statsProcess
        command: [
            "sh", "-c",
            "read _ u n s i w x y z _ < /proc/stat; t1=$((u+n+s+i+w+x+y+z)); a1=$((u+n+s+x+y+z)); "
            + "sleep 0.15; read _ u n s i w x y z _ < /proc/stat; t2=$((u+n+s+i+w+x+y+z)); a2=$((u+n+s+x+y+z)); "
            + "dt=$((t2-t1)); [ \"$dt\" -gt 0 ] || exit 1; cpu=$((100*(a2-a1)/dt)); "
            + "mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{if(t>0)printf \"%d\",100*(t-a)/t}' /proc/meminfo); "
            + "disk=$(df -P / | awk 'NR==2{gsub(/%/,\"\",$5);print $5}'); "
            + "up=$(awk '{d=int($1/86400);h=int(($1%86400)/3600);m=int(($1%3600)/60);if(d>0)printf \"%dd %dh\",d,h;else if(h>0)printf \"%dh %dm\",h,m;else printf \"%dm\",m}' /proc/uptime); "
            + "temp=$(for f in /sys/class/thermal/thermal_zone*/temp; do [ -r \"$f\" ] && awk '{printf \"%.1f\",$1/1000;exit}' \"$f\" && break; done); "
            + "printf 'cpu=%s\\nmemory=%s\\ndisk=%s\\nuptime=%s\\ntemperature=%s\\n' \"$cpu\" \"$mem\" \"$disk\" \"$up\" \"${temp:-0}\"; "
            + "ps -eo pid=,pcpu=,pmem=,comm= --sort=-pcpu | awk 'NR<=5{printf \"process=%s\\t%s\\t%s\\t%s\\n\",$1,$2,$3,$4}'"
        ]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
        onExited: (exitCode, exitStatus) => {
            watchdog.stop()
            if (exitCode !== 0) {
                root.clear()
                root.error = "System sampling failed (exit " + exitCode + ")"
            }
        }
    }

    Timer {
        id: watchdog
        interval: 15000
        onTriggered: {
            if (!statsProcess.running) return
            statsProcess.running = false
            root.clear()
            root.error = "System sampling timed out"
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
