pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int volume: 0
    property bool muted: false

    function parse(contents) {
        for (const line of contents.trim().split("\n")) {
            const sep = line.indexOf("=")
            if (sep <= 0) continue
            const key = line.slice(0, sep)
            const val = line.slice(sep + 1)
            if (key === "volume")
                root.volume = Math.max(0, Math.min(100, Math.round(Number(val))))
            else if (key === "muted")
                root.muted = val === "true"
        }
    }

    function setVolume(percent) {
        volumeSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@",
            Math.max(0, Math.min(100, percent)) + "%"]
        volumeSetProc.running = true
    }

    function toggleMute() {
        muteProc.running = true
    }

    Process {
        id: pollProc
        command: [
            "sh", "-c",
            "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); "
            + "pct=$(echo \"$vol\" | awk '{printf \"%d\",$2*100}'); "
            + "mut=$(echo \"$vol\" | grep -q MUTED && echo true || echo false); "
            + "printf 'volume=%s\\nmuted=%s\\n' \"$pct\" \"$mut\""
        ]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Process {
        id: volumeSetProc
        onExited: pollProc.running = true
    }

    Process {
        id: muteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        onExited: pollProc.running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!pollProc.running) pollProc.running = true }
    }
}
