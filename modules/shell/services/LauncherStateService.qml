pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int schemaVersion: 1
    readonly property int recentLimit: 10
    readonly property string stateHome: {
        const configured = Quickshell.env("XDG_STATE_HOME")
        return configured || (Quickshell.env("HOME") + "/.local/state")
    }
    readonly property string stateDirectory: stateHome + "/arch-wm-shell"
    readonly property string statePath: stateDirectory + "/launcher.json"

    property var favorites: []
    property var recents: []
    property string pendingContents: ""

    signal stateSaved()

    function emptyState() {
        return { schemaVersion: root.schemaVersion, favorites: [], recents: [] }
    }

    function knownDesktopIds() {
        return [...DesktopEntries.applications.values].map(entry => entry.id)
    }

    function uniqueKnown(values, knownIds, limit) {
        if (!Array.isArray(values))
            return []

        const known = new Set(Array.isArray(knownIds) ? knownIds : root.knownDesktopIds())
        const result = []
        for (const value of values) {
            if (typeof value !== "string" || !known.has(value) || result.indexOf(value) !== -1)
                continue
            result.push(value)
            if (limit > 0 && result.length >= limit)
                break
        }
        return result
    }

    function normalize(value, knownIds) {
        if (!value || value.schemaVersion !== root.schemaVersion)
            return root.emptyState()
        return {
            schemaVersion: root.schemaVersion,
            favorites: root.uniqueKnown(value.favorites, knownIds, 0),
            recents: root.uniqueKnown(value.recents, knownIds, root.recentLimit)
        }
    }

    function parse(contents, knownIds) {
        try {
            if (typeof contents !== "string" || contents.trim().length === 0)
                return root.emptyState()
            return root.normalize(JSON.parse(contents), knownIds)
        } catch (error) {
            return root.emptyState()
        }
    }

    function load(contents) {
        const normalized = root.parse(contents)
        root.favorites = normalized.favorites
        root.recents = normalized.recents
    }

    function isFavorite(desktopId) {
        return root.favorites.indexOf(desktopId) !== -1
    }

    function isKnown(desktopId) {
        return typeof desktopId === "string" && !!DesktopEntries.byId(desktopId)
    }

    function toggleFavorite(desktopId) {
        if (!root.isKnown(desktopId))
            return false

        const next = root.favorites.slice()
        const index = next.indexOf(desktopId)
        if (index === -1)
            next.push(desktopId)
        else
            next.splice(index, 1)
        root.favorites = next
        root.save()
        return true
    }

    function recordLaunch(desktopId) {
        if (!root.isKnown(desktopId))
            return false

        const next = root.recents.filter(value => value !== desktopId)
        next.unshift(desktopId)
        root.recents = next.slice(0, root.recentLimit)
        root.save()
        return true
    }

    function save() {
        root.pendingContents = JSON.stringify({
            schemaVersion: root.schemaVersion,
            favorites: root.favorites,
            recents: root.recents
        }, null, 2) + "\n"

        if (directoryProcess.running)
            return
        directoryProcess.running = true
    }

    Process {
        id: directoryProcess
        command: ["mkdir", "-p", root.stateDirectory]
        onExited: (exitCode) => {
            if (exitCode === 0 && root.pendingContents.length > 0)
                stateFile.setText(root.pendingContents)
            else if (exitCode !== 0)
                console.warn("Launcher state directory creation failed with exit code " + exitCode)
        }
    }

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        printErrors: false
        atomicWrites: true
        onLoaded: root.load(stateFile.text())
        onTextChanged: root.load(stateFile.text())
        onFileChanged: stateFile.reload()
        onSaved: root.stateSaved()
        onSaveFailed: (error) => console.warn("Launcher state save failed: " + error)
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.load(stateFile.text())
        }
    }

    Component.onCompleted: root.load(stateFile.text())
}
