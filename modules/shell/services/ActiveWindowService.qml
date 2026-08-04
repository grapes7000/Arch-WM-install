pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string title: "Desktop"
    property string appClass: ""

    function parse(contents) {
        try {
            const value = JSON.parse(contents)
            root.title = value && value.title ? value.title : "Desktop"
            root.appClass = value && value.class ? value.class : ""
        } catch (error) {
            root.title = "Desktop"
            root.appClass = ""
        }
    }

    Process {
        id: activeWindow
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!activeWindow.running)
                activeWindow.running = true
        }
    }
}
