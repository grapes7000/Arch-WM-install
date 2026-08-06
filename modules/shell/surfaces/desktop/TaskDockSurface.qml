import QtQuick
import Quickshell
import "../../core" as Core

Scope {
    id: root

    property var dockWindows: []

    function registerDock(window) {
        const windows = dockWindows.slice()
        windows.push(window)
        dockWindows = windows
    }

    function unregisterDock(window) {
        dockWindows = dockWindows.filter(candidate => candidate !== window)
    }

    function dockFor(screen) {
        if (!screen)
            return null
        for (const dock of dockWindows) {
            if (dock.modelData && dock.modelData.name === screen.name)
                return dock
        }
        return null
    }

    function invoke(action, screen) {
        const dock = dockFor(screen)
        if (!dock || typeof dock[action] !== "function")
            return false
        return dock[action]() === true
    }

    function open(screen) { return invoke("open", screen) }
    function toggle(screen) { return invoke("toggle", screen) }

    function close(screen) {
        if (screen)
            return invoke("close", screen)
        for (const dock of dockWindows)
            dock.close()
        return true
    }

    Component.onCompleted: Core.InteractiveShellController.dockController = root
    Component.onDestruction: {
        if (Core.InteractiveShellController.dockController === root)
            Core.InteractiveShellController.dockController = null
    }

    Variants {
        model: Quickshell.screens

        TaskDockWindow {
            Component.onCompleted: root.registerDock(this)
            Component.onDestruction: root.unregisterDock(this)
        }
    }
}
