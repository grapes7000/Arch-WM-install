pragma Singleton

import QtQml

QtObject {
    id: root

    property bool locked: false
    property var launcherController: null
    property var drawerController: null
<<<<<<< Updated upstream
    property var dockController: null
=======
    property var menuController: null
>>>>>>> Stashed changes

    readonly property var drawerKinds: [
        "calendar",
        "audio",
        "network",
<<<<<<< Updated upstream
        "system-stats",
        "notifications",
        "session",
        "weather",
        "media"
=======
        "system",
        "notifications",
        "session",
        "weather"
>>>>>>> Stashed changes
    ]

    function invoke(controller, action, args) {
        if (root.locked || !controller || typeof controller[action] !== "function")
            return false
        return controller[action].apply(controller, args) === true
    }

    function launcher(action) {
<<<<<<< Updated upstream
        const screen = ScreenResolver.resolve("")
        if (!screen)
            return false
=======
        if (root.locked)
            return false
        const screen = ScreenResolver.resolve("")
        if (!screen)
            return false
        if (action === "open" || action === "toggle") {
            closeController(root.drawerController)
            closeController(root.menuController)
        }
>>>>>>> Stashed changes
        return invoke(root.launcherController, action, [screen])
    }

    function drawersOpen(kind, screenName) {
<<<<<<< Updated upstream
        if (root.drawerKinds.indexOf(kind) === -1)
=======
        if (root.locked || root.drawerKinds.indexOf(kind) === -1)
>>>>>>> Stashed changes
            return false
        const screen = ScreenResolver.resolve(screenName)
        if (!screen)
            return false
<<<<<<< Updated upstream
=======
        closeController(root.launcherController)
        closeController(root.menuController)
>>>>>>> Stashed changes
        return invoke(root.drawerController, "open", [kind, null, screen])
    }

    function drawersClose() {
        return invoke(root.drawerController, "close", [])
    }

<<<<<<< Updated upstream
    function dock(action) {
        const screen = ScreenResolver.resolve("")
        if (!screen)
            return false
        return invoke(root.dockController, action, [screen])
    }

    function requestFromBar(capability, payload, screen) {
        if (capability !== "drawer.open" || !payload)
=======
    function requestFromBar(capability, payload, screen) {
        if (root.locked || capability !== "drawer.open" || !payload)
>>>>>>> Stashed changes
            return false
        const kind = typeof payload.kind === "string" ? payload.kind : ""
        if (root.drawerKinds.indexOf(kind) === -1)
            return false
<<<<<<< Updated upstream
        return invoke(root.drawerController, "open", [kind, payload.anchorItem || null, screen])
    }

    function closeAll() {
        if (root.launcherController && typeof root.launcherController.close === "function")
            root.launcherController.close()
        if (root.drawerController && typeof root.drawerController.close === "function")
            root.drawerController.close()
        if (root.dockController && typeof root.dockController.close === "function")
            root.dockController.close()
=======
        closeController(root.launcherController)
        closeController(root.menuController)
        return invoke(root.drawerController, "open", [kind, payload.anchorItem || null, screen])
    }

    function prepareMenuOpen() {
        if (root.locked)
            return false
        closeController(root.launcherController)
        closeController(root.drawerController)
        return true
    }

    function closeController(controller) {
        if (controller && typeof controller.close === "function")
            controller.close()
    }

    function closeAll() {
        closeController(root.launcherController)
        closeController(root.drawerController)
        closeController(root.menuController)
>>>>>>> Stashed changes
    }

    onLockedChanged: {
        if (locked)
            closeAll()
    }
}
