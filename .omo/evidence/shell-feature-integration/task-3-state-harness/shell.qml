import QtQuick
import Quickshell
import ArchWmShell as Services

ShellRoot {
    Component.onCompleted: {
        console.log("STATE_KEYS=" + Object.keys(Services.LauncherStateService).join(","))
        Services.LauncherStateService.load("{broken")
        if (Services.LauncherStateService.favorites.length !== 0 || Services.LauncherStateService.recents.length !== 0)
            throw new Error("malformed state was not rejected")

        const normalized = Services.LauncherStateService.normalize({
            schemaVersion: 1,
            favorites: ["fixture-one", "stale", "fixture-one"],
            recents: ["fixture-two", "fixture-one", "fixture-two", "stale"]
        }, ["fixture-one", "fixture-two"])
        if (JSON.stringify(normalized.favorites) !== JSON.stringify(["fixture-one"]))
            throw new Error("favorites were not normalized")
        if (JSON.stringify(normalized.recents) !== JSON.stringify(["fixture-two", "fixture-one"]))
            throw new Error("recents were not normalized")

        const entries = [...DesktopEntries.applications.values]
        const fixture = entries.find(entry => entry.name === "Arch WM Fixture One")
        if (!fixture)
            throw new Error("fixture desktop entry was not loaded")
        console.log("STATE_CONTRACT_OK id=" + fixture.id)
        if (!Services.LauncherStateService.recordLaunch(fixture.id))
            throw new Error("fixture launch was not recorded")
    }

    Connections {
        target: Services.LauncherStateService
        function onStateSaved() {
            console.log("STATE_SAVED_OK")
            Qt.quit()
        }
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: { console.warn("STATE_SAVE_TIMEOUT"); Qt.quit() }
    }
}
