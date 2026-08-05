pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int count: 0
    property bool dndEnabled: false

    function parse(contents) {
        for (const line of contents.trim().split("\n")) {
            const sep = line.indexOf("=")
            if (sep <= 0) continue
            const key = line.slice(0, sep)
            const val = line.slice(sep + 1)
            if (key === "count")
                root.count = Math.max(0, Number(val))
            else if (key === "dnd")
                root.dndEnabled = val === "true"
        }
    }

    function dismiss() {
        dismissProc.running = true
    }

    function toggleDnd() {
        dndProc.running = true
    }

    Process {
        id: pollProc
        command: [
            "sh", "-c",
            "if command -v swaync-client >/dev/null 2>&1; then "
            + "  c=$(swaync-client -c 2>/dev/null || echo 0); "
            + "  d=$(swaync-client -D 2>/dev/null | grep -q true && echo true || echo false); "
            + "  printf 'count=%s\\ndnd=%s\\n' \"$c\" \"$d\"; "
            + "elif command -v dunstctl >/dev/null 2>&1; then "
            + "  c=$(dunstctl count waiting 2>/dev/null || echo 0); "
            + "  d=$(dunstctl is-paused 2>/dev/null | grep -q true && echo true || echo false); "
            + "  printf 'count=%s\\ndnd=%s\\n' \"$c\" \"$d\"; "
            + "else printf 'count=0\\ndnd=false\\n'; fi"
        ]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Process {
        id: dismissProc
        command: ["sh", "-c",
            "command -v swaync-client >/dev/null 2>&1 && swaync-client -C || "
            + "command -v dunstctl >/dev/null 2>&1 && dunstctl close-all"]
        onExited: pollProc.running = true
    }

    Process {
        id: dndProc
        command: ["sh", "-c",
            "command -v swaync-client >/dev/null 2>&1 && swaync-client -d || "
            + "command -v dunstctl >/dev/null 2>&1 && dunstctl set-paused toggle"]
        onExited: pollProc.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!pollProc.running) pollProc.running = true }
    }
}
