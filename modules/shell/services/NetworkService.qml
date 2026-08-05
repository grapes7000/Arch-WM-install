pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool connected: false
    property string ssid: ""
    property string type: ""
    property int strength: 0

    function parse(contents) {
        for (const line of contents.trim().split("\n")) {
            const sep = line.indexOf("=")
            if (sep <= 0) continue
            const key = line.slice(0, sep)
            const val = line.slice(sep + 1)
            if (key === "connected") root.connected = val === "yes"
            else if (key === "ssid") root.ssid = val
            else if (key === "type") root.type = val
            else if (key === "strength") root.strength = Math.max(0, Math.min(100, Number(val)))
        }
    }

    Process {
        id: pollProc
        command: [
            "sh", "-c",
            "state=$(nmcli -t -f STATE general status 2>/dev/null || echo 'disconnected'); "
            + "conn='no'; [ \"$state\" = 'connected' ] && conn='yes'; "
            + "wifi=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -1); "
            + "ssid=$(echo \"$wifi\" | cut -d: -f2); "
            + "sig=$(echo \"$wifi\" | cut -d: -f3); "
            + "typ='ethernet'; [ -n \"$ssid\" ] && typ='wifi'; "
            + "printf 'connected=%s\\nssid=%s\\ntype=%s\\nstrength=%s\\n' "
            + "\"$conn\" \"$ssid\" \"$typ\" \"${sig:-0}\""
        ]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!pollProc.running) pollProc.running = true }
    }
}
