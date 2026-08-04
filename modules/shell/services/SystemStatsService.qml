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
    property string error: ""

    function parse(contents) {
        const result = ({})
        for (const raw of contents.trim().split("\n")) {
            const separator = raw.indexOf("=")
            if (separator > 0)
                result[raw.slice(0, separator)] = raw.slice(separator + 1)
        }
        if (result.cpu !== undefined)
            root.cpuPercent = Math.max(0, Math.min(100, Number(result.cpu)))
        if (result.memory !== undefined)
            root.memoryPercent = Math.max(0, Math.min(100, Number(result.memory)))
        if (result.disk !== undefined)
            root.diskPercent = Math.max(0, Math.min(100, Number(result.disk)))
        if (result.uptime !== undefined)
            root.uptime = result.uptime
        root.error = ""
    }

    Process {
        id: statsProcess
        command: [
            "sh", "-c",
            "read _ u n s i w x y z _ < /proc/stat; "
            + "t1=$((u+n+s+i+w+x+y+z)); a1=$((u+n+s+x+y+z)); "
            + "sleep 0.15; read _ u n s i w x y z _ < /proc/stat; "
            + "t2=$((u+n+s+i+w+x+y+z)); a2=$((u+n+s+x+y+z)); "
            + "cpu=$((100*(a2-a1)/(t2-t1))); "
            + "mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf \"%d\",100*(t-a)/t}' /proc/meminfo); "
            + "disk=$(df -P / | awk 'NR==2{gsub(/%/,\"\",$5);print $5}'); "
            + "up=$(awk '{d=int($1/86400);h=int(($1%86400)/3600);m=int(($1%3600)/60); if(d>0) printf \"%dd %dh\",d,h; else if(h>0) printf \"%dh %dm\",h,m; else printf \"%dm\",m}' /proc/uptime); "
            + "printf 'cpu=%s\\nmemory=%s\\ndisk=%s\\nuptime=%s\\n' \"$cpu\" \"$mem\" \"$disk\" \"$up\""
        ]

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statsProcess.running)
                statsProcess.running = true
        }
    }
}
