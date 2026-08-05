pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string temp: "--"
    property string condition: ""
    property string icon: ""
    property bool available: false

    function parse(contents) {
        for (const line of contents.trim().split("\n")) {
            const sep = line.indexOf("=")
            if (sep <= 0) continue
            const key = line.slice(0, sep)
            const val = line.slice(sep + 1)
            if (key === "temp") { root.temp = val; root.available = true }
            else if (key === "condition") root.condition = val
            else if (key === "icon") root.icon = val
        }
    }

    Process {
        id: pollProc
        command: [
            "sh", "-c",
            "data=$(curl -sf 'wttr.in/?format=%t|%C|%c' 2>/dev/null) || exit 0; "
            + "temp=$(echo \"$data\" | cut -d'|' -f1 | tr -d '+'); "
            + "cond=$(echo \"$data\" | cut -d'|' -f2); "
            + "ico=$(echo \"$data\" | cut -d'|' -f3 | tr -d ' '); "
            + "printf 'temp=%s\\ncondition=%s\\nicon=%s\\n' \"$temp\" \"$cond\" \"$ico\""
        ]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!pollProc.running) pollProc.running = true }
    }
}
