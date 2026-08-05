pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var widgets: ({})
    property string error: ""
    property string _shellDir: ""

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
            console.warn("Widget registry update rejected:", failure)
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
        return "file://" + root._shellDir + "/widgets/" + widgetId + "/" + item.entry
    }

    Process {
        id: registryProc
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    Component.onCompleted: {
        var base = Quickshell.env("XDG_CONFIG_HOME")
        if (!base) base = Quickshell.env("HOME") + "/.config"
        root._shellDir = base + "/quickshell/arch-wm"
        registryProc.command = ["cat", root._shellDir + "/generated/widgets.json"]
        registryProc.running = true
    }
}
