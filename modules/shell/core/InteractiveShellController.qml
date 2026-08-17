pragma Singleton

import QtQml

QtObject {
    id: root

    property bool locked: false
    property bool homepageVisible: true
    property var launcherController: null
    property var drawerController: null
    property var dockController: null
    property var menuController: null

    readonly property var drawerKinds: [
        "calendar",
        "audio",
        "network",
        "system",
        "notifications",
        "session",
        "weather",
        "battery"
    ]

    function invoke(controller, action, args) {
        if (root.locked || !controller || typeof controller[action] !== "function")
            return false
        return controller[action].apply(controller, args) === true
    }

    function launcher(action) {
        if (root.locked)
            return false
        const screen = ScreenResolver.resolve("")
        if (!screen)
            return false
        if (action === "open" || action === "toggle") {
            closeController(root.drawerController)
            closeController(root.menuController)
        }
        return invoke(root.launcherController, action, [screen])
    }

    function drawersOpen(kind, screenName) {
        if (root.locked || root.drawerKinds.indexOf(kind) === -1)
            return false
        const screen = ScreenResolver.resolve(screenName)
        if (!screen)
            return false
        closeController(root.launcherController)
        closeController(root.menuController)
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

    function homepage(action) {
        if (action === "show")
            root.homepageVisible = true
        else if (action === "hide")
            root.homepageVisible = false
        else if (action === "toggle")
            root.homepageVisible = !root.homepageVisible
        else
            return false
        return true
    }

    function requestFromBar(capability, payload, screen) {
        if (root.locked || capability !== "drawer.open" || !payload)
            return false
        const kind = typeof payload.kind === "string" ? payload.kind : ""
        if (root.drawerKinds.indexOf(kind) === -1)
            return false
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
        closeController(root.dockController)
    }

    onLockedChanged: {
        if (locked)
            closeAll()
    }
}
