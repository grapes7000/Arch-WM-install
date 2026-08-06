pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool running: false
    property bool connected: false
    property string tailnet: ""
    property bool exitNodeActive: false
    property string exitNodeName: ""
    property bool isMullvad: false
    property string mullvadLocation: ""
    property string ipAddress: ""
    property int peerCount: 0

    function parse(contents) {
        if (!contents || contents.length === 0) {
            root.running = false
            root.connected = false
            return
        }

        try {
            const data = JSON.parse(contents)
            root.running = data.BackendState === "Running"
            root.connected = root.running && data.Self && data.Self.Online === true

            if (data.CurrentTailnet && data.CurrentTailnet.Name)
                root.tailnet = data.CurrentTailnet.Name
            else
                root.tailnet = ""

            if (data.Self && data.Self.TailscaleIPs && data.Self.TailscaleIPs.length > 0)
                root.ipAddress = data.Self.TailscaleIPs[0]
            else
                root.ipAddress = ""

            const peers = data.Peer ? Object.keys(data.Peer) : []
            root.peerCount = peers.length

            let exitId = ""
            if (data.ExitNodeStatus && data.ExitNodeStatus.ID)
                exitId = data.ExitNodeStatus.ID

            root.exitNodeActive = exitId !== ""
            root.exitNodeName = ""
            root.isMullvad = false
            root.mullvadLocation = ""

            if (exitId && data.Peer) {
                for (const key of Object.keys(data.Peer)) {
                    const peer = data.Peer[key]
                    if (peer.ID === exitId || peer.PublicKey === exitId) {
                        root.exitNodeName = peer.HostName || peer.DNSName || "unknown"
                        const lower = root.exitNodeName.toLowerCase()
                        root.isMullvad = lower.indexOf("mullvad") !== -1
                        if (root.isMullvad) {
                            const parts = lower.split(/[-.]+/)
                            if (parts.length >= 2)
                                root.mullvadLocation = parts[0].toUpperCase()
                                    + "-" + parts[1].toUpperCase()
                        }
                        break
                    }
                }
            }
        } catch (e) {
            console.warn("TailscaleService parse error:", e)
        }
    }

    Process {
        id: pollProc
        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!pollProc.running) pollProc.running = true }
    }
}
