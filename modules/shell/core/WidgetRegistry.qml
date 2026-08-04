pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var widgets: ({})
    property string error: ""

    function parse(contents) {
        if (!contents || contents.trim().length === 0)
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
        path: Quickshell.shellRoot + "/generated/widgets.json"
        blockLoading: true
        watchChanges: true
        onTextChanged: root.parse(text)
        onFileChanged: reload()
    }

    Component.onCompleted: root.parse(registryFile.text)
}
