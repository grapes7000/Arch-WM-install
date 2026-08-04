pragma Singleton

import QtQuick

QtObject {
    id: root

    // Replace this bootstrap map with schema-validated manifest discovery.
    readonly property var bootstrap: ({
        "clock": {
            entry: Qt.resolvedUrl("../widgets/clock/Widget.qml"),
            surfaces: ["bar", "desktop", "lockscreen"],
            lockSafe: true
        }
    })

    function definition(widgetId) {
        return bootstrap[widgetId] || null
    }

    function supports(widgetId, surface, locked) {
        const item = definition(widgetId)
        if (!item || item.surfaces.indexOf(surface) === -1)
            return false
        return !locked || item.lockSafe === true
    }
}
