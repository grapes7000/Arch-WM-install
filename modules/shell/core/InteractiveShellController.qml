pragma Singleton

import QtQml

QtObject {
    id: root

    property bool locked: false
    property var launcherController: null
    property var drawerController: null
    property var dockController: null

    readonly property var drawerKinds: [
        "calendar",
        "audio",
        "network",
        "system",
        "notifications",
        "session",
        "weather"
    ]

    function invoke(controller, action, args) {
        if (root.locked || !controller || typeof controller[action] !== "function")
            return false
        return controller[action].apply(controller, args) === true
    }

    function launcher(action) {
        const screen = ScreenResolver.resolve("")
        if (!screen)
            return false
        return invoke(root.launcherController, action, [screen])
    }

    function drawersOpen(kind, screenName) {
        if (root.drawerKinds.indexOf(kind) === -1)
            return false
        const screen = ScreenResolver.resolve(screenName)
        if (!screen)
            return false
        return invoke(root.drawerController, "open", [kind, null, screen])
    }

    function drawersClose() {
        return invoke(root.drawerController, "close", [])
    }

    function dock(action) {
        const screen = ScreenResolver.resolve("")
        if (!screen)
            return false
        return invoke(root.dockController, action, [screen])
    }

    function requestFromBar(capability, payload, screen) {
        if (capability !== "drawer.open" || !payload)
            return false
        const kind = typeof payload.kind === "string" ? payload.kind : ""
        if (root.drawerKinds.indexOf(kind) === -1)
            return false
        return invoke(root.drawerController, "open", [kind, payload.anchorItem || null, screen])
    }

    function closeAll() {
        if (root.launcherController && typeof root.launcherController.close === "function")
            root.launcherController.close()
        if (root.drawerController && typeof root.drawerController.close === "function")
            root.drawerController.close()
        if (root.dockController && typeof root.dockController.close === "function")
            root.dockController.close()
    }

    onLockedChanged: {
        if (locked)
            closeAll()
    }
}
