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
    property string ipAddress: ""
    property string security: ""
    property string downloadRate: "Idle"
    property string uploadRate: "Idle"

    property real _prevRx: 0
    property real _prevTx: 0
    property bool _hasPrev: false

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
            else if (key === "ip") root.ipAddress = val
            else if (key === "security") root.security = val
            else if (key === "rx_bytes") {
                const rx = Number(val)
                if (root._hasPrev && rx >= root._prevRx) {
                    const delta = rx - root._prevRx
                    root.downloadRate = delta > 0
                        ? (delta / 1024).toFixed(0) + " KiB/s" : "Idle"
                }
                root._prevRx = rx
            } else if (key === "tx_bytes") {
                const tx = Number(val)
                if (root._hasPrev && tx >= root._prevTx) {
                    const delta = tx - root._prevTx
                    root.uploadRate = delta > 0
                        ? (delta / 1024).toFixed(0) + " KiB/s" : "Idle"
                }
                root._prevTx = tx
                root._hasPrev = true
            }
        }
    }

    Process {
        id: pollProc
        command: [
            "sh", "-c",
            "state=$(nmcli -t -f STATE general status 2>/dev/null || echo 'disconnected'); "
            + "conn='no'; [ \"$state\" = 'connected' ] && conn='yes'; "
            + "wifi=$(nmcli -t -f active,ssid,signal,security dev wifi 2>/dev/null | grep '^yes' | head -1); "
            + "ssid=$(echo \"$wifi\" | cut -d: -f2); "
            + "sig=$(echo \"$wifi\" | cut -d: -f3); "
            + "sec=$(echo \"$wifi\" | cut -d: -f4); "
            + "typ='ethernet'; [ -n \"$ssid\" ] && typ='wifi'; "
            + "dev=$(ip route show default 2>/dev/null | awk '{print $5; exit}'); "
            + "ip=$(ip -4 -o addr show dev \"$dev\" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1); "
            + "rx=0; tx=0; "
            + "if [ -n \"$dev\" ] && [ -f /proc/net/dev ]; then "
            + "  line=$(grep \"$dev\" /proc/net/dev); "
            + "  rx=$(echo \"$line\" | awk -F: '{print $2}' | awk '{print $1}'); "
            + "  tx=$(echo \"$line\" | awk -F: '{print $2}' | awk '{print $9}'); "
            + "fi; "
            + "printf 'connected=%s\\nssid=%s\\ntype=%s\\nstrength=%s\\nip=%s\\nsecurity=%s\\nrx_bytes=%s\\ntx_bytes=%s\\n' "
            + "\"$conn\" \"$ssid\" \"$typ\" \"${sig:-0}\" \"${ip:-}\" \"${sec:-}\" \"${rx:-0}\" \"${tx:-0}\""
        ]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!pollProc.running) pollProc.running = true }
    }
}
