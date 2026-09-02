pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// One shared BlueZ process keeps every Bluetooth widget instance in sync.
Singleton {
    id: root

    property bool powered: false
    property bool discovering: false
    property var devices: []
    property string error: ""
    property string _operation: ""
    property string _output: ""
    property var _pendingDevices: []
    property var _scannedNames: ({})
    property int _detailIndex: 0
    readonly property bool busy: serviceProcess.running

    function parsePowered(contents) {
        powered = /Powered:\s*yes/.test(contents)
        return true
    }

    function parseDevices(contents) {
        const next = []
        for (const line of contents.split("\n")) {
            const match = /^Device\s+([0-9A-F:]{17})\s+(.+)$/.exec(line.trim())
            if (!match) continue
            next.push({ address: match[1], name: match[2].trim(), alias: "",
                        advertisedName: _scannedNames[match[1]] || "",
                        connected: false, paired: false, icon: "" })
        }
        // bluetoothctl's live scan reports a device name before it is present
        // in the cached `devices` list. Keep those candidates, otherwise
        // earbuds such as AirPods can only appear as an opaque address.
        for (const address in _scannedNames) {
            if (next.some(device => device.address === address)) continue
            next.push({ address: address, name: "", alias: "",
                        advertisedName: _scannedNames[address], connected: false,
                        paired: false, icon: "" })
        }
        _pendingDevices = next
        _detailIndex = 0
        devices = next
        return true
    }

    function parseScanDevices(contents) {
        const names = ({})
        for (const line of contents.split("\n")) {
            const match = /\[(?:NEW|CHG)\]\s+Device\s+([0-9A-F:]{17})\s+(.+)$/.exec(line.trim())
            if (!match) continue
            const label = match[2].trim()
            if (!label || /^(RSSI|TxPower|ManufacturerData|ServiceData):/.test(label)) continue
            names[match[1]] = label
        }
        _scannedNames = names
        return true
    }

    function parseDeviceInfo(contents, address) {
        const index = _pendingDevices.findIndex(device => device.address === address)
        if (index < 0) return false
        const next = _pendingDevices.slice()
        const device = Object.assign({}, next[index])
        const name = /^\s*Name:\s*(.+)$/m.exec(contents)
        const alias = /^\s*Alias:\s*(.+)$/m.exec(contents)
        const icon = /^\s*Icon:\s*(.+)$/m.exec(contents)
        // BlueZ aliases are user-facing labels; the advertising Name is often
        // an opaque model or serial-like identifier.
        device.alias = alias ? alias[1].trim() : ""
        device.name = name ? name[1].trim() : device.name
        device.connected = /^\s*Connected:\s*yes\s*$/m.test(contents)
        device.paired = /^\s*Paired:\s*yes\s*$/m.test(contents)
        device.icon = icon ? icon[1].trim() : ""
        next[index] = device
        _pendingDevices = next
        devices = next
        return true
    }

    function run(command, operation) {
        if (serviceProcess.running) return false
        _operation = operation
        _output = ""
        serviceProcess.command = command
        serviceProcess.running = true
        watchdog.restart()
        return true
    }

    function refresh() {
        if (serviceProcess.running) return false
        error = ""
        return run(["bluetoothctl", "show"], "status")
    }

    function requestDevices() {
        if (!powered) {
            devices = []
            return true
        }
        return run(["bluetoothctl", "devices"], "devices")
    }

    function requestNextDeviceDetail() {
        if (_detailIndex >= _pendingDevices.length) return true
        return run(["bluetoothctl", "info", _pendingDevices[_detailIndex].address], "deviceInfo")
    }

    function setPower(enabled) {
        return run(["bluetoothctl", "power", enabled ? "on" : "off"], "powerSet")
    }

    function scan() {
        if (!powered || serviceProcess.running) return false
        discovering = true
        _scannedNames = ({})
        return run(["bluetoothctl", "--timeout", "10", "scan", "on"], "scan")
    }

    function connect(address) {
        if (!powered || !address) return false
        return run(["bluetoothctl", "connect", address], "connect")
    }

    function pair(address) {
        if (!powered || !address) return false
        return run(["bluetoothctl", "pair", address], "pair")
    }

    function disconnect(address) {
        if (!address) return false
        return run(["bluetoothctl", "disconnect", address], "disconnect")
    }

    Process {
        id: serviceProcess
        stdout: StdioCollector { onStreamFinished: root._output = text }
        onExited: (exitCode, exitStatus) => {
            watchdog.stop()
            const operation = root._operation
            const output = root._output
            root._operation = ""
            root._output = ""
            command = []
            if (exitCode !== 0) {
                if (operation === "deviceInfo") {
                    root._detailIndex += 1
                    Qt.callLater(root.requestNextDeviceDetail)
                    return
                }
                if (operation === "status") {
                    root.powered = false
                    root.devices = []
                }
                root.discovering = false
                root.error = operation + " failed (exit " + exitCode + ")"
                return
            }
            if (operation === "status") {
                root.parsePowered(output)
                Qt.callLater(root.requestDevices)
            } else if (operation === "devices") {
                root.parseDevices(output)
                Qt.callLater(root.requestNextDeviceDetail)
            } else if (operation === "deviceInfo") {
                if (root._detailIndex < root._pendingDevices.length)
                    root.parseDeviceInfo(output, root._pendingDevices[root._detailIndex].address)
                root._detailIndex += 1
                Qt.callLater(root.requestNextDeviceDetail)
            } else if (operation === "scan") {
                root.discovering = false
                root.parseScanDevices(output)
                Qt.callLater(root.refresh)
            } else if (operation === "powerSet" || operation === "connect"
                       || operation === "disconnect" || operation === "pair") {
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
            root.powered = false
            root.discovering = false
            root.error = root._operation + " timed out"
            root._operation = ""
            root._output = ""
            serviceProcess.command = []
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
