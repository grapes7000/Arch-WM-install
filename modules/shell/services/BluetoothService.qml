pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool powered: false
    property string error: ""
    property string _operation: ""

    function parsePowered(contents) {
        powered = /Powered:\s*yes/.test(contents)
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
        return run(["bluetoothctl", "show"], "status")
    }

    function setPower(enabled) {
        return run(["bluetoothctl", "power", enabled ? "on" : "off"], "powerSet")
    }

    Process {
        id: serviceProcess
        stdout: StdioCollector {
            onStreamFinished: {
                if (root._operation === "status") root.parsePowered(text)
            }
        }
        onExited: (exitCode, exitStatus) => {
            watchdog.stop()
            const operation = root._operation
            root._operation = ""
            command = []
            if (exitCode !== 0) {
                if (operation === "status") root.powered = false
                root.error = operation + " failed (exit " + exitCode + ")"
            } else if (operation === "powerSet") {
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
