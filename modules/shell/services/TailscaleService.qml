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
    property string error: ""
    property string statusText: ""
    property bool statusLoading: false
    // Exit nodes that route out through Mullvad even though their
    // hostname doesn't literally contain "mullvad" (e.g. a homelab
    // box whose own uplink is a Mullvad WireGuard tunnel).
    readonly property var mullvadRoutedExitNodes: ["homelab"]

    function refreshStatusText() {
        if (statusProc.running) return
        statusLoading = true
        statusProc.running = true
    }

    function clear(message) {
        running = false
        connected = false
        tailnet = ""
        exitNodeActive = false
        exitNodeName = ""
        isMullvad = false
        mullvadLocation = ""
        ipAddress = ""
        peerCount = 0
        error = message || ""
    }

    function parse(contents) {
        if (!contents || contents.length === 0) {
            clear("Tailscale returned no status")
            return false
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
                        const directlyMullvad = lower.indexOf("mullvad") !== -1
                        const routesViaMullvad = root.mullvadRoutedExitNodes.some(
                            name => lower.indexOf(name) !== -1)
                        root.isMullvad = directlyMullvad || routesViaMullvad
                        if (directlyMullvad) {
                            const parts = lower.split(/[-.]+/)
                            if (parts.length >= 2)
                                root.mullvadLocation = parts[0].toUpperCase()
                                    + "-" + parts[1].toUpperCase()
                        } else if (routesViaMullvad) {
                            root.mullvadLocation = "via " + root.exitNodeName
                        }
                        break
                    }
                }
            }
            error = ""
            return true
        } catch (e) {
            clear("Malformed Tailscale status")
            return false
        }
    }

    Process {
        id: pollProc
        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
        onExited: (exitCode, exitStatus) => {
            watchdog.stop()
            if (exitCode !== 0) root.clear("Tailscale unavailable (exit " + exitCode + ")")
        }
    }

    Process {
        id: statusProc
        command: ["tailscale", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.statusText = text
                root.statusLoading = false
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.statusText = "tailscale status failed (exit " + exitCode + ")"
                root.statusLoading = false
            }
        }
    }

    Timer {
        id: watchdog
        interval: 15000
        onTriggered: {
            if (!pollProc.running) return
            pollProc.running = false
            root.clear("Tailscale status timed out")
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!pollProc.running) {
                pollProc.running = true
                watchdog.restart()
            }
        }
    }
}
