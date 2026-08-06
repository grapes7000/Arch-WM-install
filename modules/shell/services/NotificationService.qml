pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int count: 0
    property bool dndEnabled: false
    property var recent: []
    property string error: ""
    property string _operation: ""

    function clearHistory() {
        count = 0
        recent = []
    }

    function parseHistory(contents) {
        try {
            const document = JSON.parse(contents)
            const rows = []
            function visit(value) {
                if (Array.isArray(value)) {
                    for (const child of value) visit(child)
                } else if (value && typeof value === "object") {
                    const summary = value.summary && value.summary.data !== undefined ? value.summary.data : value.summary
                    const body = value.body && value.body.data !== undefined ? value.body.data : value.body
                    const app = value.appname && value.appname.data !== undefined ? value.appname.data : value.appname
                    if (summary !== undefined || body !== undefined) {
                        rows.push({ appName: String(app || ""), summary: String(summary || ""), body: String(body || "") })
                    } else for (const key of Object.keys(value)) visit(value[key])
                }
            }
            visit(document.data !== undefined ? document.data : document)
            recent = rows.slice(0, 5)
            count = rows.length
            error = ""
            return true
        } catch (exception) {
            clearHistory()
            error = "Malformed Dunst history"
            return false
        }
    }

    function parsePaused(contents) {
        const value = contents.trim()
        if (value !== "true" && value !== "false") {
            dndEnabled = false
            error = "Malformed Dunst pause state"
            return false
        }
        dndEnabled = value === "true"
        error = ""
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

    function refresh() { return run(["dunstctl", "history"], "history") }
    function dismiss() { return run(["dunstctl", "close-all"], "dismiss") }
    function toggleDnd() { return run(["dunstctl", "set-paused", "toggle"], "toggle") }

    Process {
        id: serviceProcess
        stdout: StdioCollector {
            onStreamFinished: {
                if (root._operation === "history") root.parseHistory(text)
                else if (root._operation === "paused") root.parsePaused(text)
            }
        }
        onExited: (exitCode, exitStatus) => {
            watchdog.stop()
            const operation = root._operation
            root._operation = ""
            command = []
            if (exitCode !== 0) {
                if (operation === "history") root.clearHistory()
                if (operation === "paused") root.dndEnabled = false
                root.error = operation + " failed (exit " + exitCode + ")"
            } else if (operation === "history") {
                Qt.callLater(() => root.run(["dunstctl", "is-paused"], "paused"))
            } else if (operation === "dismiss" || operation === "toggle") {
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
            root.clearHistory()
            root.dndEnabled = false
            root.error = root._operation + " timed out"
            root._operation = ""
            serviceProcess.command = []
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
