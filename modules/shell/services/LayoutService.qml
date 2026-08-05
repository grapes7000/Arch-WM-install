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

    readonly property string _shellDir: {
        var url = Qt.resolvedUrl("..")
        var s = url.toString()
        if (s.startsWith("file://")) s = s.substring(7)
        if (s.endsWith("/")) s = s.substring(0, s.length - 1)
        return s
    }

    function parse(contents, expectedSurface) {
        if (!contents || typeof contents !== "string" || contents.length === 0)
            throw new Error("empty " + expectedSurface + " layout")
        const parsed = JSON.parse(contents)
        if (parsed.surface !== expectedSurface || !parsed.regions)
            throw new Error("invalid " + expectedSurface + " layout")
        return parsed
    }

    FileView {
        id: barFile
        path: root._shellDir + "/layouts/bar.default.json"
        blockLoading: true
        watchChanges: true
        onTextChanged: {
            try {
                root.bar = root.parse(barFile.text, "bar")
            } catch (error) {
                console.warn("Bar layout rejected; keeping last known-good layout:", error)
            }
        }
        onFileChanged: barFile.reload()
    }

    FileView {
        id: desktopFile
        path: root._shellDir + "/layouts/desktop.default.json"
        blockLoading: true
        watchChanges: true
        onTextChanged: {
            try {
                root.desktop = root.parse(desktopFile.text, "desktop")
            } catch (error) {
                console.warn("Desktop layout rejected; keeping last known-good layout:", error)
            }
        }
        onFileChanged: desktopFile.reload()
    }

    Component.onCompleted: {
        try { root.bar = root.parse(barFile.text, "bar") } catch (error) {}
        try { root.desktop = root.parse(desktopFile.text, "desktop") } catch (error) {}
    }
}
