pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string title: ""
    property string artist: ""
    property string status: "Stopped"
    property bool canNext: false
    property bool canPrev: false
    property string error: ""
    property string _operation: ""

    function clear() {
        title = ""
        artist = ""
        status = "Stopped"
        canNext = false
        canPrev = false
    }

    function parse(contents) {
        const fields = contents.trim().split("\t")
        if (fields.length !== 5 || !["Playing", "Paused", "Stopped"].includes(fields[2])) {
            clear()
            error = contents.trim() ? "Malformed player metadata" : "No active media player"
            return false
        }
        title = fields[0]
        artist = fields[1]
        status = fields[2]
        canNext = fields[3] === "true"
        canPrev = fields[4] === "true"
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

    function refresh() {
        return run([
            "playerctl", "metadata", "--format",
            "{{title}}\t{{artist}}\t{{status}}\t{{mpris:canGoNext}}\t{{mpris:canGoPrevious}}"
        ], "poll")
    }
    function playPause() { return run(["playerctl", "play-pause"], "action") }
    function next() { return run(["playerctl", "next"], "action") }
    function previous() { return run(["playerctl", "previous"], "action") }

    Process {
        id: serviceProcess
        stdout: StdioCollector { onStreamFinished: { if (root._operation === "poll") root.parse(text) } }
        onExited: (exitCode, exitStatus) => {
            watchdog.stop()
            const operation = root._operation
            root._operation = ""
            command = []
            if (exitCode !== 0) {
                root.clear()
                root.error = operation === "poll" ? "No active media player" : "Media action failed (exit " + exitCode + ")"
            } else if (operation === "action") Qt.callLater(root.refresh)
        }
    }

    Timer {
        id: watchdog
        interval: 15000
        onTriggered: {
            if (!serviceProcess.running) return
            serviceProcess.running = false
            root.clear()
            root.error = root._operation + " timed out"
            root._operation = ""
            serviceProcess.command = []
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
