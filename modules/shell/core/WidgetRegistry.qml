pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var widgets: ({
        "workspaces": {
            id: "workspaces",
            entry: "Widget.qml",
            surfaces: ["bar", "desktop"],
            variants: ["compact", "standard"],
            lockSafe: false,
            capabilities: ["workspace.switch"]
        },
        "active-window": {
            id: "active-window",
            entry: "Widget.qml",
            surfaces: ["bar", "desktop"],
            variants: ["compact", "standard"],
            lockSafe: false,
            capabilities: []
        },
        "clock": {
            id: "clock",
            entry: "Widget.qml",
            surfaces: ["bar", "desktop", "lockscreen"],
            variants: ["compact", "standard", "expanded"],
            lockSafe: true,
            capabilities: []
        },
        "system-stats": {
            id: "system-stats",
            entry: "Widget.qml",
            surfaces: ["bar", "desktop"],
            variants: ["compact", "standard", "expanded"],
            lockSafe: false,
            capabilities: []
        }
    })
    property string error: ""

    readonly property string registryPath: Quickshell.shellDir + "/generated/widgets.json"

    function parse(contents) {
        if (!contents || typeof contents !== "string" || contents.length === 0)
            return
        try {
            const parsed = JSON.parse(contents)
            if (!Array.isArray(parsed.widgets))
                throw new Error("registry requires a widgets array")
            const next = ({})
            for (const definition of parsed.widgets) {
                if (!definition.id || !definition.entry)
                    throw new Error("widget definition requires id and entry")
                if (next[definition.id])
                    throw new Error("duplicate widget id: " + definition.id)
                next[definition.id] = definition
            }
            root.widgets = next
            root.error = ""
        } catch (failure) {
            root.error = String(failure)
            console.warn("Widget registry update rejected; using last known-good registry:", failure)
        }
    }

    function definition(widgetId) {
        return widgets[widgetId] || null
    }

    function supports(widgetId, surface, locked) {
        const item = definition(widgetId)
        if (!item || !Array.isArray(item.surfaces)
                || item.surfaces.indexOf(surface) === -1)
            return false
        return !locked || item.lockSafe === true
    }

    function entryUrl(widgetId) {
        const item = definition(widgetId)
        if (!item)
            return ""
        return Qt.resolvedUrl("../widgets/" + widgetId + "/" + item.entry)
    }

    FileView {
        id: registryFile
        path: root.registryPath
        blockLoading: true
        watchChanges: true
        onTextChanged: root.parse(registryFile.text())
        onFileChanged: registryFile.reload()
    }

    Component.onCompleted: root.parse(registryFile.text())
}
