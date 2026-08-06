pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool running: cavaProcess.running && available
    property var bars: []
    property string error: ""

    function clear(message) {
        available = false
        bars = []
        error = message || ""
    }

    function parse(line) {
        const fields = line.trim().split(";").filter(value => value !== "")
        if (fields.length === 0 || fields.length > 24) {
            clear("Malformed Cava output")
            return false
        }
        const parsed = fields.map(value => Number(value))
        if (!parsed.every(Number.isFinite)) {
            clear("Malformed Cava output")
            return false
        }
        bars = parsed.slice(0, 24).map(value => Math.max(0, Math.min(1, value / 1000)))
        available = true
        error = ""
        return true
    }

    function start() {
        if (cavaProcess.running) return
        cavaProcess.command = ["cava", "-p", Qt.resolvedUrl("cava.conf").toString().replace("file://", "")]
        cavaProcess.running = true
    }

    Process {
        id: cavaProcess
        stdout: SplitParser { onRead: data => root.parse(data) }
        onExited: (exitCode, exitStatus) => {
            command = []
            root.clear(exitCode === 0 ? "Cava stopped" : "Cava unavailable (exit " + exitCode + ")")
            restartTimer.restart()
        }
    }

    Timer {
        id: restartTimer
        interval: 10000
        onTriggered: root.start()
    }

    Component.onCompleted: start()
}
