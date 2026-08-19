import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components

Scope {
    id: root

    property string query: ""
    property string category: "All"
    property int selectedIndex: 0
    property int appsRevision: 0
    readonly property var categories: [
        { name: "All", icon: "applications-all" },
        { name: "Favorites", icon: "starred" },
        { name: "Recent", icon: "document-open-recent" },
        { name: "Internet", icon: "applications-internet" },
        { name: "Development", icon: "applications-development" },
        { name: "Utilities", icon: "applications-utilities" },
        { name: "System", icon: "applications-system" },
        { name: "Multimedia", icon: "applications-multimedia" },
        { name: "Office", icon: "applications-office" },
        { name: "Games", icon: "applications-games" },
        { name: "Other", icon: "applications-other" }
    ]
    readonly property var results: buildResults()

    function entryCategory(entry) {
        const values = entry.categories || []
        if (values.some(value => ["Network", "WebBrowser", "Email"].indexOf(value) !== -1)) return "Internet"
        if (values.some(value => ["Development", "IDE", "TextEditor"].indexOf(value) !== -1)) return "Development"
        if (values.some(value => ["Utility", "FileManager", "Archiving"].indexOf(value) !== -1)) return "Utilities"
        if (values.some(value => ["System", "Settings", "Security"].indexOf(value) !== -1)) return "System"
        if (values.some(value => ["AudioVideo", "Audio", "Video", "Player"].indexOf(value) !== -1)) return "Multimedia"
        if (values.some(value => ["Office", "WordProcessor", "Spreadsheet"].indexOf(value) !== -1)) return "Office"
        if (values.indexOf("Game") !== -1) return "Games"
        return "Other"
    }

    function searchScore(entry, needle) {
        if (!needle) return 0
        const name = String(entry.name || "").toLowerCase()
        if (name === needle) return 500
        if (name.startsWith(needle)) return 400
        if (name.indexOf(needle) !== -1) return 300
        const secondary = [entry.genericName, entry.comment, ...(entry.keywords || [])].join(" ").toLowerCase()
        return secondary.indexOf(needle) !== -1 ? 200 : -1
    }

    function buildResults() {
        const _entriesVersion = root.appsRevision // re-run this binding when the app list changes
        const needle = root.query.trim().toLowerCase()
        const favorites = Services.LauncherStateService.favorites
        const recents = Services.LauncherStateService.recents
        let entries = [...DesktopEntries.applications.values].filter(entry => !entry.noDisplay)
        entries = entries.filter(entry => {
            if (root.searchScore(entry, needle) < 0) return false
            if (root.category === "Favorites") return favorites.indexOf(entry.id) !== -1
            if (root.category === "Recent") return recents.indexOf(entry.id) !== -1
            return root.category === "All" || root.entryCategory(entry) === root.category
        })
        return entries.sort((left, right) => {
            const searchDelta = root.searchScore(right, needle) - root.searchScore(left, needle)
            if (searchDelta) return searchDelta
            if (root.category === "Recent") return recents.indexOf(left.id) - recents.indexOf(right.id)
            const favoriteDelta = Number(favorites.indexOf(right.id) !== -1) - Number(favorites.indexOf(left.id) !== -1)
            if (favoriteDelta) return favoriteDelta
            const leftRecent = recents.indexOf(left.id)
            const rightRecent = recents.indexOf(right.id)
            if (leftRecent !== -1 || rightRecent !== -1)
                return (leftRecent === -1 ? 999 : leftRecent) - (rightRecent === -1 ? 999 : rightRecent)
            return String(left.name).localeCompare(String(right.name))
        })
    }

    function open(screen) {
        if (!session.open(screen)) return false
        root.query = ""
        root.category = "All"
        root.selectedIndex = 0
        Qt.callLater(() => searchField.forceActiveFocus())
        return true
    }
    function close() { root.query = ""; return session.close() }
    function toggle(screen) { return session.visible ? root.close() : root.open(screen) }
    function launch(entry) {
        if (!entry || Services.LockStateService.locked) return false
        Services.LauncherStateService.recordLaunch(entry.id)
        entry.execute()
        root.close()
        return true
    }

    onResultsChanged: selectedIndex = Math.max(0, Math.min(selectedIndex, results.length - 1))

    LauncherSession { id: session; locked: Services.LockStateService.locked }
    Binding {
        target: Core.InteractiveShellController
        property: "launcherController"
        value: root
        restoreMode: Binding.RestoreBindingOrValue
    }
    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.appsRevision++ }
    }

    PanelWindow {
        id: launcherWindow

        property real revealProgress: 1.0

        function startReveal() {
            launcherReveal.stop()
            if (Core.Theme.motionScale <= 0.05) {
                revealProgress = 1.0
                return
            }
            revealProgress = 0.0
            launcherReveal.restart()
        }

        screen: session.screen
        visible: session.visible && !Services.LockStateService.locked
        anchors { top: true; right: true; bottom: true; left: true }
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "arch-wm-launcher"

        onVisibleChanged: {
            if (visible)
                Qt.callLater(launcherWindow.startReveal)
            else {
                launcherReveal.stop()
                revealProgress = Core.Theme.motionScale <= 0.05 ? 1.0 : 0.0
            }
        }

        NumberAnimation {
            id: launcherReveal
            target: launcherWindow
            property: "revealProgress"
            from: 0.0
            to: 1.0
            duration: Math.round(Math.max(210, Core.Theme.animationMs * 1.4) * Core.Theme.motionScale)
            easing.type: Easing.OutBack
            easing.overshoot: 1.12
        }

        Rectangle {
            anchors.fill: parent
            color: {
                const c = Qt.color(Core.Theme.background)
                return Qt.rgba(c.r, c.g, c.b, 0.82)
            }
            opacity: Math.max(0.0, Math.min(1.0, launcherWindow.revealProgress))
            MouseArea { anchors.fill: parent; onClicked: root.close() }

            Rectangle {
                id: launcherCard
                anchors.centerIn: parent
                width: Math.min(parent.width - Core.Theme.gap * 6, 900)
                height: Math.min(parent.height - Core.Theme.gap * 10, 650)
                radius: Core.Theme.radius
                color: Core.Theme.surface
                border.width: Core.Theme.borderWidth
                border.color: Core.Theme.accent2
                opacity: Math.max(0.0, Math.min(1.0, launcherWindow.revealProgress))
                scale: 0.91 + launcherWindow.revealProgress * 0.09
                transform: Translate {
                    y: (1.0 - launcherWindow.revealProgress) * 16
                }
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Core.Theme.gap * 2
                    spacing: Core.Theme.gap
                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Search applications"
                        text: root.query
                        color: Core.Theme.foreground
                        placeholderTextColor: Core.Theme.muted
                        font.family: Core.Theme.fontFamily
                        font.pixelSize: 21
                        background: Rectangle {
                            color: Core.Theme.background
                            radius: Core.Theme.radius
                            border.width: Core.Theme.borderWidth
                            border.color: searchField.activeFocus ? Core.Theme.accent : Core.Theme.accent2
                        }
                        onTextChanged: root.query = text
                        Keys.onUpPressed: root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                        Keys.onDownPressed: root.selectedIndex = Math.min(root.results.length - 1, root.selectedIndex + 1)
                        Keys.onReturnPressed: root.launch(root.results[root.selectedIndex])
                        Keys.onEnterPressed: root.launch(root.results[root.selectedIndex])
                        Keys.onEscapePressed: root.close()
                    }
                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        orientation: ListView.Horizontal
                        spacing: Core.Theme.gap
                        model: root.categories
                        clip: true
                        delegate: Rectangle {
                            required property var modelData
                            width: categoryRow.implicitWidth + Core.Theme.gap * 3
                            height: 32
                            radius: Core.Theme.radius
                            color: root.category === modelData.name ? Core.Theme.accent2 : Core.Theme.background
                            RowLayout {
                                id: categoryRow
                                anchors.centerIn: parent
                                spacing: 6
                                IconImage { Layout.preferredWidth: 16; Layout.preferredHeight: 16; source: Quickshell.iconPath(modelData.icon, "") }
                                Text { font.family: Core.Theme.fontFamily; text: modelData.name; color: Core.Theme.foreground }
                            }
                            MouseArea { id: categoryArea; anchors.fill: parent; onClicked: { root.category = modelData.name; root.selectedIndex = 0; searchField.forceActiveFocus() } }
                            Components.PressBounce { pressed: categoryArea.pressed }
                        }
                    }
                    ListView {
                        id: appList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: root.results
                        currentIndex: root.selectedIndex
                        clip: true
                        spacing: Math.max(2, Core.Theme.gap / 2)
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: 6
                                radius: 3
                                color: Core.Theme.accent2
                                opacity: parent.pressed ? 0.9 : 0.5
                            }
                        }
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: appList.width
                            height: 58
                            radius: Core.Theme.radius
                            color: index === root.selectedIndex ? Core.Theme.background : "transparent"
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Core.Theme.gap
                                spacing: Core.Theme.gap
                                IconImage { Layout.preferredWidth: 36; Layout.preferredHeight: 36; source: Quickshell.iconPath(modelData.icon, "application-x-executable") }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text { font.family: Core.Theme.fontFamily; text: modelData.name; color: Core.Theme.foreground; font.pixelSize: 19; elide: Text.ElideRight; Layout.fillWidth: true }
                                    Text { font.family: Core.Theme.fontFamily; text: modelData.comment || root.entryCategory(modelData); color: Core.Theme.muted; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                                Text {
                                    font.family: Core.Theme.fontFamily
                                    text: Services.LauncherStateService.isFavorite(modelData.id) ? "Unfavorite" : "Favorite"
                                    color: Core.Theme.accent
                                    MouseArea { id: favoriteArea; anchors.fill: parent; anchors.margins: -Core.Theme.gap; onClicked: Services.LauncherStateService.toggleFavorite(modelData.id) }
                                    Components.PressBounce { pressed: favoriteArea.pressed }
                                }
                            }
                            MouseArea { id: appLaunchArea; anchors.fill: parent; z: -1; hoverEnabled: true; onEntered: root.selectedIndex = index; onClicked: root.launch(modelData) }
                            Components.PressBounce { pressed: appLaunchArea.pressed }
                        }
                        Text { font.family: Core.Theme.fontFamily; anchors.centerIn: parent; visible: appList.count === 0; text: "No matching applications"; color: Core.Theme.muted }
                    }
                }
            }
        }
    }
}
