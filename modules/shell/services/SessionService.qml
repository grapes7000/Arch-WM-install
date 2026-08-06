pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string pendingAction: ""
    property string error: ""
    property bool busy: actionProcess.running

    function commandFor(action) {
        if (action === "logout") return ["hyprctl", "dispatch", "exit"]
        if (action === "suspend") return ["systemctl", "suspend"]
        if (action === "reboot") return ["systemctl", "reboot"]
        if (action === "poweroff") return ["systemctl", "poweroff"]
        return []
    }

    function execute(command) {
        if (actionProcess.running) {
            error = "Another session action is running"
            return false
        }
        error = ""
        actionProcess.command = command
        actionProcess.running = true
        watchdog.restart()
        return true
    }

    function lock() {
        pendingAction = ""
        confirmation.stop()
        return execute(["loginctl", "lock-session"])
    }

    function confirm(action) {
        const command = commandFor(action)
        if (command.length === 0) {
            error = "Unknown session action"
            return false
        }
        if (pendingAction !== action) {
            pendingAction = action
            error = ""
            confirmation.restart()
            return false
        }
        pendingAction = ""
        confirmation.stop()
        return execute(command)
    }

    function logout() { return confirm("logout") }
    function suspend() { return confirm("suspend") }
    function reboot() { return confirm("reboot") }
    function poweroff() { return confirm("poweroff") }
    function cancel() { pendingAction = ""; confirmation.stop() }

    Process {
        id: actionProcess
        onExited: (exitCode, exitStatus) => {
            watchdog.stop()
            command = []
            if (exitCode !== 0) root.error = "Session action failed (exit " + exitCode + ")"
        }
    }

    Timer {
        id: confirmation
        interval: 4000
        onTriggered: root.pendingAction = ""
    }

    Timer {
        id: watchdog
        interval: 15000
        onTriggered: {
            if (!actionProcess.running) return
            actionProcess.running = false
            actionProcess.command = []
            root.error = "Session action timed out"
        }
    }
}
