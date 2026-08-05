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

    function parse(contents, expectedSurface) {
        if (typeof contents !== "string" || contents.trim().length === 0)
            throw new Error("empty " + expectedSurface + " layout")
        const parsed = JSON.parse(contents)
        if (parsed.surface !== expectedSurface || !parsed.regions)
            throw new Error("invalid " + expectedSurface + " layout")
        return parsed
    }

    function reloadBar() {
        try {
            root.bar = root.parse(barFile.text(), "bar")
        } catch (error) {
            console.warn("Bar layout rejected; keeping last known-good layout:", error)
        }
    }

    function reloadDesktop() {
        try {
            root.desktop = root.parse(desktopFile.text(), "desktop")
        } catch (error) {
            console.warn("Desktop layout rejected; keeping last known-good layout:", error)
        }
    }

    FileView {
        id: barFile
        path: Quickshell.shellDir + "/layouts/bar.default.json"
        blockLoading: true
        watchChanges: true
        onTextChanged: root.reloadBar()
        onFileChanged: reload()
    }

    FileView {
        id: desktopFile
        path: Quickshell.shellDir + "/layouts/desktop.default.json"
        blockLoading: true
        watchChanges: true
        onTextChanged: root.reloadDesktop()
        onFileChanged: reload()
    }

    Component.onCompleted: {
        root.reloadBar()
        root.reloadDesktop()
    }
}
