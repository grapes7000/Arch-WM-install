pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var bar: ({
        surface: "bar",
        regions: { start: [], center: [], end: [] }
    })
    property var desktop: ({
        surface: "desktop",
        regions: { top_right: [] }
    })

    property string _shellDir: ""

    function parse(contents, expectedSurface) {
        if (!contents || typeof contents !== "string" || contents.length === 0)
            throw new Error("empty " + expectedSurface + " layout")
        const parsed = JSON.parse(contents)
        if (parsed.surface !== expectedSurface || !parsed.regions)
            throw new Error("invalid " + expectedSurface + " layout")
        return parsed
    }

    Process {
        id: barProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.bar = root.parse(text, "bar")
                } catch (error) {
                    console.warn("Bar layout rejected:", error)
                }
            }
        }
    }

    Process {
        id: desktopProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.desktop = root.parse(text, "desktop")
                } catch (error) {
                    console.warn("Desktop layout rejected:", error)
                }
            }
        }
    }

    Component.onCompleted: {
        var base = Quickshell.env("XDG_CONFIG_HOME")
        if (!base) base = Quickshell.env("HOME") + "/.config"
        root._shellDir = base + "/quickshell/arch-wm"
        barProc.command = ["cat", root._shellDir + "/layouts/bar.default.json"]
        barProc.running = true
        desktopProc.command = ["cat", root._shellDir + "/layouts/desktop.default.json"]
        desktopProc.running = true
    }
}
