import QtQml

QtObject {
    id: root

    property bool locked: false
    property bool visible: false
    property string activeKind: ""
    property var anchorItem: null
    property var screen: null

    readonly property var validKinds: [
        "calendar",
        "audio",
        "network",
        "system",
        "notifications",
        "session",
        "weather"
    ]

    function open(kind, targetAnchor, targetScreen) {
        if (root.locked || root.validKinds.indexOf(kind) === -1 || !targetScreen)
            return false

        root.visible = false
        root.activeKind = kind
        root.anchorItem = targetAnchor || null
        root.screen = targetScreen
        root.visible = true
        return true
    }

    function close() {
        root.visible = false
        root.activeKind = ""
        root.anchorItem = null
        root.screen = null
        return true
    }

    onLockedChanged: {
        if (locked)
            close()
    }
}
