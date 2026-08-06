pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string sessionId: String(Quickshell.env("XDG_SESSION_ID") || "")
    property bool locked: false

    function applyLockedHint(contents) {
        const hint = String(contents).trim().toLowerCase()
        if (hint === "yes") {
            root.locked = true
            return true
        }
        if (hint === "no") {
            root.locked = false
            return true
        }
        return false
    }

    Process {
        id: lockPoll
        command: [
            "loginctl",
            "show-session",
            root.sessionId,
            "-p",
            "LockedHint",
            "--value"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.applyLockedHint(text)
        }
    }

    Timer {
        interval: 1000
        running: root.sessionId.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!lockPoll.running)
                lockPoll.running = true
        }
    }
}
