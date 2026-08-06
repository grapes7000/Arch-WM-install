pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var bar: ({
        surface: "bar",
        regions: {
            start: [
                { instance: "workspaces-fallback", widget: "workspaces", variant: "compact" },
                { instance: "active-fallback", widget: "active-window", variant: "compact" }
            ],
            center: [
                { instance: "clock-fallback", widget: "clock", variant: "compact" }
            ],
            end: [
                { instance: "system-fallback", widget: "system-stats", variant: "compact" }
            ]
        }
    })
    property var desktop: ({
        surface: "desktop",
        regions: {
            top_right: [
                { instance: "clock-desktop-fallback", widget: "clock", variant: "expanded" },
                { instance: "system-desktop-fallback", widget: "system-stats", variant: "expanded" }
            ]
        }
    })

    readonly property string shellDir: Quickshell.shellDir

    function readFile(fv) {
        try { var r = fv.text(); if (typeof r === "string") return r } catch(e) {}
        try { var r2 = fv.text; if (typeof r2 === "string") return r2 } catch(e) {}
        return ""
    }

    function parse(contents, expectedSurface) {
        if (!contents || typeof contents !== "string" || contents.length === 0)
            throw new Error("empty " + expectedSurface + " layout")
        const parsed = JSON.parse(contents)
        if (parsed.surface !== expectedSurface || !parsed.regions)
            throw new Error("invalid " + expectedSurface + " layout")

        for (const regionName of Object.keys(parsed.regions)) {
            if (!Array.isArray(parsed.regions[regionName]))
                throw new Error(expectedSurface + " region is not an array: " + regionName)
        }
        return parsed
    }

    FileView {
        id: barFile
        path: root.shellDir + "/layouts/bar.default.json"
        watchChanges: true
        onTextChanged: {
            try {
                root.bar = root.parse(root.readFile(barFile), "bar")
            } catch (error) {
                console.warn("Bar layout rejected; keeping last known-good layout:", error)
            }
        }
    }

    FileView {
        id: desktopFile
        path: root.shellDir + "/layouts/desktop.default.json"
        watchChanges: true
        onTextChanged: {
            try {
                root.desktop = root.parse(root.readFile(desktopFile), "desktop")
            } catch (error) {
                console.warn("Desktop layout rejected; keeping last known-good layout:", error)
            }
        }
    }

    Component.onCompleted: {
        try {
            root.bar = root.parse(root.readFile(barFile), "bar")
        } catch (error) {
            console.warn("Using fallback bar layout:", error)
        }
        try {
            root.desktop = root.parse(root.readFile(desktopFile), "desktop")
        } catch (error) {
            console.warn("Using fallback desktop layout:", error)
        }
    }
}
