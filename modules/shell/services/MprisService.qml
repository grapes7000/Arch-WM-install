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

    function parse(contents) {
        for (const line of contents.trim().split("\n")) {
            const sep = line.indexOf("=")
            if (sep <= 0) continue
            const key = line.slice(0, sep)
            const val = line.slice(sep + 1)
            if (key === "title") root.title = val
            else if (key === "artist") root.artist = val
            else if (key === "status") root.status = val
            else if (key === "canNext") root.canNext = val === "true"
            else if (key === "canPrev") root.canPrev = val === "true"
        }
    }

    function playPause() { actionProc.command = ["playerctl", "play-pause"]; actionProc.running = true }
    function next() { actionProc.command = ["playerctl", "next"]; actionProc.running = true }
    function previous() { actionProc.command = ["playerctl", "previous"]; actionProc.running = true }

    Process {
        id: pollProc
        command: [
            "sh", "-c",
            "t=$(playerctl metadata title 2>/dev/null || echo ''); "
            + "a=$(playerctl metadata artist 2>/dev/null || echo ''); "
            + "s=$(playerctl status 2>/dev/null || echo 'Stopped'); "
            + "cn=$(playerctl metadata 2>/dev/null && echo true || echo false); "
            + "printf 'title=%s\\nartist=%s\\nstatus=%s\\ncanNext=%s\\ncanPrev=%s\\n' "
            + "\"$t\" \"$a\" \"$s\" \"$cn\" \"$cn\""
        ]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Process { id: actionProc; onExited: pollProc.running = true }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!pollProc.running) pollProc.running = true }
    }
}
