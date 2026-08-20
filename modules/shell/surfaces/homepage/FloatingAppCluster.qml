import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../services" as Services

Item {
    id: root

    property var fallbackApps: []
    property int columns: 3
    property int appsRevision: 0

    readonly property var appModels: {
        void root.appsRevision
        const chosen = []
        const favoriteIds = Services.LauncherStateService.favorites.slice(0, 6)
        for (const desktopId of favoriteIds) {
            const entry = DesktopEntries.byId(desktopId)
            if (entry)
                chosen.push({
                    entry: entry,
                    label: root.shortLabel(entry.name),
                    iconName: entry.icon,
                    fallbackIcon: "󰀻",
                    command: ""
                })
        }

        for (const fallback of root.fallbackApps) {
            if (chosen.length >= 6)
                break
            const entry = root.desktopEntryFor(fallback.command)
            if (entry && chosen.some(model => model.entry && model.entry.id === entry.id))
                continue
            chosen.push({
                entry: entry,
                label: fallback.name,
                iconName: entry ? entry.icon : "",
                fallbackIcon: fallback.icon,
                command: fallback.command
            })
        }
        return chosen.slice(0, 6)
    }

    implicitWidth: appGrid.implicitWidth
    implicitHeight: appGrid.implicitHeight

    function desktopEntryFor(command) {
        if (!command)
            return null
        const binary = command.trim().split(" ")[0].split("/").pop().toLowerCase()
        return [...DesktopEntries.applications.values].find(entry => {
            const id = String(entry.id || "").toLowerCase()
            const executable = String(entry.execString || "")
                .trim().split(" ")[0].split("/").pop().toLowerCase()
            return executable === binary || id === binary || id === binary + ".desktop"
        }) || null
    }

    function shortLabel(name) {
        const text = String(name || "App").trim()
        if (text.length <= 10)
            return text
        const firstWord = text.split(/[ (]/)[0]
        return firstWord.length <= 10 ? firstWord : firstWord.slice(0, 9) + "…"
    }

    function launch(model) {
        if (!model || Services.LockStateService.locked)
            return
        if (model.entry) {
            Services.LauncherStateService.recordLaunch(model.entry.id)
            model.entry.execute()
            return
        }
        if (!model.command || fallbackProcess.running)
            return
        fallbackProcess.command = ["sh", "-lc", model.command]
        fallbackProcess.running = true
    }

    Process {
        id: fallbackProcess
        onExited: command = []
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.appsRevision++
        }
    }

    GridLayout {
        id: appGrid
        anchors.fill: parent
        columns: root.columns
        rowSpacing: 4
        columnSpacing: 6

        Repeater {
            model: root.appModels

            FloatingAppShortcut {
                required property var modelData
                Layout.preferredWidth: 76
                Layout.preferredHeight: 76
                label: modelData.label
                iconName: modelData.iconName
                fallbackIcon: modelData.fallbackIcon
                onActivated: root.launch(modelData)
            }
        }
    }
}
