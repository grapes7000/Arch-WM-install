pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var widgets: ({})
    property string error: ""

    readonly property string _shellDir: {
        var url = Qt.resolvedUrl("..")
        var s = url.toString()
        if (s.startsWith("file://")) s = s.substring(7)
        if (s.endsWith("/")) s = s.substring(0, s.length - 1)
        return s
    }

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
        return Qt.resolvedUrl("../widgets/" + widgetId + "/" + item.entry)
    }

    FileView {
        id: registryFile
        path: root._shellDir + "/generated/widgets.json"
        blockLoading: true
        watchChanges: true
        onTextChanged: root.parse(registryFile.text)
        onFileChanged: registryFile.reload()
    }

    Component.onCompleted: root.parse(registryFile.text)
}
