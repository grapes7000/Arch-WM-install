import QtQml

QtObject {
    id: root

    property bool visible: false
    property bool locked: false
    property var screen: null

    function open(targetScreen) {
        if (root.locked || !targetScreen)
            return false
        root.screen = targetScreen
        root.visible = true
        return true
    }

    function close() {
        root.visible = false
        root.screen = null
        return true
    }

    function toggle(targetScreen) {
        if (root.visible)
            return root.close()
        return root.open(targetScreen)
    }

    onLockedChanged: {
        if (locked)
            close()
    }
}
