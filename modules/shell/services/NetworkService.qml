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
    property var activeConnection: ({})
    property var accessPoints: []
    property bool scanning: false
    property bool connecting: false
    property string error: ""
    property string _operation: ""

    function splitEscaped(line) {
        const fields = []
        let value = ""
        let escaped = false
        for (const character of line) {
            if (escaped) {
                value += character
                escaped = false
            } else if (character === "\\") {
                escaped = true
            } else if (character === ":") {
                fields.push(value)
                value = ""
            } else value += character
        }
        fields.push(value)
        return fields
    }

    function clearActive() {
        connected = false
        ssid = ""
        type = ""
        strength = 0
        ipAddress = ""
        security = ""
        downloadRate = "Idle"
        uploadRate = "Idle"
        activeConnection = ({})
    }

    function parseStatus(contents) {
        let active = null
        for (const raw of contents.trim().split("\n")) {
            if (!raw) continue
            const fields = splitEscaped(raw)
            if (fields.length !== 4) continue
            if (fields[2] === "connected" && fields[3] && fields[3] !== "--") {
                active = { device: fields[0], type: fields[1] === "wifi" ? "wifi" : "ethernet", name: fields[3] }
                if (fields[1] === "wifi") break
            }
        }
        if (!active) {
            clearActive()
            error = contents.trim() ? "No active connection" : "nmcli returned no device state"
            return false
        }
        connected = true
        type = active.type
        ssid = active.type === "wifi" ? active.name : ""
        activeConnection = active
        error = ""
        return true
    }

    function parseScan(contents) {
        const rows = []
        let malformed = false
        for (const raw of contents.trim().split("\n")) {
            if (!raw) continue
            const fields = splitEscaped(raw)
            if (fields.length !== 4) {
                malformed = true
                continue
            }
            if (!fields[1]) continue
            const row = {
                active: fields[0] === "yes" || fields[0] === "*",
                ssid: fields[1],
                strength: Math.max(0, Math.min(100, Number(fields[2]) || 0)),
                security: fields[3]
            }
            if (!rows.some(item => item.ssid === row.ssid)) rows.push(row)
        }
        accessPoints = rows
        if (malformed) error = "Malformed Wi-Fi scan"
        const current = rows.find(row => row.active)
        if (current) {
            strength = current.strength
            security = current.security
        }
        scanning = false
        return !malformed
    }

    function parseDetails(contents) {
        let address = ""
        for (const raw of contents.trim().split("\n")) {
            if (raw.startsWith("IP4.ADDRESS")) {
                const separator = raw.indexOf(":")
                address = separator >= 0 ? raw.slice(separator + 1).split("/")[0] : ""
                break
            }
        }
        ipAddress = address
        const current = activeConnection
        activeConnection = {
            device: current.device || "",
            type: current.type || "",
            name: current.name || "",
            ipAddress: address
        }
        return true
    }

    function run(command, operation) {
        if (serviceProcess.running) return false
        _operation = operation
        serviceProcess.command = command
        serviceProcess.running = true
        watchdog.restart()
        return true
    }

    function refresh() {
        return run(["nmcli", "--terse", "--escape", "yes", "--fields", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"], "status")
    }

    function scan() {
        scanning = true
        if (!run(["nmcli", "--terse", "--escape", "yes", "--fields", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "auto"], "scan")) {
            scanning = false
            return false
        }
        return true
    }

    function connectWifi(networkSsid, password) {
        if (!networkSsid || connecting) return false
        connecting = true
        const args = ["nmcli", "--wait", "15", "device", "wifi", "connect", networkSsid]
        if (password) args.push("password", password)
        const started = run(args, "connect")
        if (started) Qt.callLater(() => { serviceProcess.command = [] })
        else connecting = false
        return started
    }

    Process {
        id: serviceProcess
        stdout: StdioCollector {
            onStreamFinished: {
                if (root._operation === "status") root.parseStatus(text)
                else if (root._operation === "scan") root.parseScan(text)
                else if (root._operation === "details") root.parseDetails(text)
            }
        }
        onExited: (exitCode, exitStatus) => {
            watchdog.stop()
            const operation = root._operation
            root._operation = ""
            command = []
            if (operation === "scan") root.scanning = false
            if (operation === "connect") root.connecting = false
            if (exitCode !== 0) {
                if (operation === "status") root.clearActive()
                if (operation === "scan") root.accessPoints = []
                root.error = operation + " failed (exit " + exitCode + ")"
            } else if (operation === "status") {
                if (root.connected && root.activeConnection.device) {
                    const device = root.activeConnection.device
                    Qt.callLater(() => root.run(["nmcli", "--terse", "--escape", "yes", "--fields", "IP4.ADDRESS", "device", "show", device], "details"))
                } else Qt.callLater(root.scan)
            } else if (operation === "details") {
                Qt.callLater(root.scan)
            } else if (operation === "connect") {
                Qt.callLater(root.refresh)
            }
        }
    }

    Timer {
        id: watchdog
        interval: 15000
        onTriggered: {
            if (!serviceProcess.running) return
            serviceProcess.running = false
            if (root._operation === "status") root.clearActive()
            if (root._operation === "scan") root.accessPoints = []
            root.scanning = false
            root.connecting = false
            root.error = root._operation + " timed out"
            root._operation = ""
            serviceProcess.command = []
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
