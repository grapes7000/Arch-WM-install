pragma Singleton

import QtQml
import Quickshell
import Quickshell.Hyprland

QtObject {
    function resolve(screenName) {
        const requestedName = String(screenName || "")
        if (requestedName.length > 0) {
            for (let index = 0; index < Quickshell.screens.length; index++) {
                const candidate = Quickshell.screens[index]
                if (candidate.name === requestedName)
                    return candidate
            }
            return null
        }

        const focused = Hyprland.focusedMonitor
        if (focused) {
            for (let index = 0; index < Quickshell.screens.length; index++) {
                const candidate = Quickshell.screens[index]
                if (candidate.name === focused.name)
                    return candidate
            }
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }
}
