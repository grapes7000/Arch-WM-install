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
    property string hoverLabel: ""
    property int hoverIndex: -1
    property real hoverCenterX: 0
    property real hoverTopY: 0
    property real hoverBottomY: 0
    property real hoverMaxY: 0
    readonly property bool gridMode: Services.LauncherStateService.viewMode === "grid"
    readonly property int gridCellBase: 92
    readonly property int gridTileSize: 66
    readonly property int gridIconSize: 46
    readonly property int gridColumns: Math.max(1, appGrid.columns)
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
        const _entriesVersion = root.appsRevision
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
        root.hoverLabel = ""
        Qt.callLater(() => searchField.forceActiveFocus())
        return true
    }
    function close() { root.query = ""; root.hoverLabel = ""; return session.close() }
    function toggle(screen) { return session.visible ? root.close() : root.open(screen) }
    function launch(entry) {
        if (!entry || Services.LockStateService.locked) return false
        Services.LauncherStateService.recordLaunch(entry.id)
        entry.execute()
        root.close()
        return true
    }

    function moveSelection(delta) {
        if (root.results.length === 0) return
        root.selectedIndex = Math.max(0, Math.min(root.results.length - 1, root.selectedIndex + delta))
    }

    function showTooltip(item, index, label) {
        const top = item.mapToItem(launcherCard, item.width / 2, 0)
        const bottom = item.mapToItem(launcherCard, item.width / 2, item.height)
        const gridTop = appGrid.mapToItem(launcherCard, 0, 0)
        root.hoverCenterX = top.x
        root.hoverTopY = top.y
        root.hoverBottomY = bottom.y
        root.hoverMaxY = gridTop.y + appGrid.height
        root.hoverIndex = index
        root.hoverLabel = String(label || "")
    }

    onGridModeChanged: root.hoverLabel = ""
    onResultsChanged: {
        selectedIndex = Math.max(0, Math.min(selectedIndex, results.length - 1))
        root.hoverLabel = ""
    }

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
            duration: Math.round((Core.UiStyle.quietButtons ? 120 : 210) * Core.Theme.motionScale)
            easing.type: Core.UiStyle.quietButtons ? Easing.OutCubic : Easing.OutBack
            easing.overshoot: Core.UiStyle.quietButtons ? 0.0 : 1.12
        }

        Rectangle {
            anchors.fill: parent
            color: Core.Theme.alphaColor(Core.Theme.background, 0.78)
            opacity: Math.max(0.0, Math.min(1.0, launcherWindow.revealProgress))
            MouseArea { anchors.fill: parent; onClicked: root.close() }

            Rectangle {
                id: launcherCard
                anchors.centerIn: parent
                width: Math.min(parent.width - Core.UiStyle.spacing3xl * 2, 820)
                height: Math.min(parent.height - Core.UiStyle.spacing3xl * 2, 600)
                radius: Core.UiStyle.radiusOverlay
                color: Core.Theme.surfaceOverlay
                border.width: Core.UiStyle.borderWidth
                border.color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.78)
                opacity: launcherWindow.revealProgress
                scale: Core.UiStyle.quietButtons ? 1.0 : (0.91 + launcherWindow.revealProgress * 0.09)
                transform: Translate {
                    y: (1.0 - launcherWindow.revealProgress) * (Core.UiStyle.quietButtons ? 6 : 16)
                }
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Core.UiStyle.spacingLg
                    spacing: Core.UiStyle.spacingSm

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Core.UiStyle.spacingSm

                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            Layout.preferredHeight: Core.UiStyle.controlHeightLarge
                            placeholderText: "Search applications"
                            text: root.query
                            color: Core.Theme.foreground
                            placeholderTextColor: Core.Theme.muted
                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.UiStyle.fontBody
                            leftPadding: Core.UiStyle.spacingMd
                            rightPadding: Core.UiStyle.spacingMd
                            selectionColor: Core.Theme.selected
                            background: Rectangle {
                                color: Core.Theme.surfaceBase
                                radius: Core.UiStyle.radiusControl
                                border.width: Core.UiStyle.focusWidth
                                border.color: searchField.activeFocus
                                    ? Core.Theme.accent
                                    : Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.70)
                            }
                            onTextChanged: root.query = text
                            Keys.onUpPressed: root.moveSelection(root.gridMode ? -root.gridColumns : -1)
                            Keys.onDownPressed: root.moveSelection(root.gridMode ? root.gridColumns : 1)
                            Keys.onLeftPressed: (event) => {
                                if (root.gridMode && searchField.text.length === 0)
                                    root.moveSelection(-1)
                                else
                                    event.accepted = false
                            }
                            Keys.onRightPressed: (event) => {
                                if (root.gridMode && searchField.text.length === 0)
                                    root.moveSelection(1)
                                else
                                    event.accepted = false
                            }
                            Keys.onReturnPressed: root.launch(root.results[root.selectedIndex])
                            Keys.onEnterPressed: root.launch(root.results[root.selectedIndex])
                            Keys.onEscapePressed: root.close()
                        }

                        Rectangle {
                            id: viewToggle
                            Layout.preferredWidth: viewToggleRow.implicitWidth + Core.UiStyle.spacingXs * 2
                            Layout.preferredHeight: Core.UiStyle.controlHeightLarge
                            radius: Core.UiStyle.radiusControl
                            color: Core.Theme.surfaceBase
                            border.width: Core.UiStyle.borderWidth
                            border.color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.70)

                            RowLayout {
                                id: viewToggleRow
                                anchors.centerIn: parent
                                spacing: Core.UiStyle.spacingXs

                                Repeater {
                                    model: [
                                        { mode: "list", label: "List view" },
                                        { mode: "grid", label: "Grid view" }
                                    ]

                                    delegate: Rectangle {
                                        id: modeButton
                                        required property var modelData
                                        readonly property bool current: Services.LauncherStateService.viewMode === modelData.mode
                                        Layout.preferredWidth: Core.UiStyle.controlHeight
                                        Layout.preferredHeight: Core.UiStyle.controlHeight - Core.UiStyle.grid
                                        radius: Core.UiStyle.radiusControl
                                        color: current
                                            ? Core.Theme.alphaColor(Core.Theme.selected, 0.16)
                                            : (modeArea.containsMouse
                                               ? Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.55)
                                               : "transparent")
                                        border.width: Core.UiStyle.borderWidth
                                        border.color: current
                                            ? Core.Theme.alphaColor(Core.Theme.accent, 0.55)
                                            : "transparent"

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Math.round(Core.Theme.animationMs * Core.Theme.motionScale)
                                            }
                                        }

                                        Column {
                                            visible: modeButton.modelData.mode === "list"
                                            anchors.centerIn: parent
                                            spacing: 2
                                            Repeater {
                                                model: 3
                                                delegate: Rectangle {
                                                    width: 13
                                                    height: 2
                                                    radius: 1
                                                    color: modeButton.current ? Core.Theme.accent : Core.Theme.foreground
                                                }
                                            }
                                        }

                                        Grid {
                                            visible: modeButton.modelData.mode === "grid"
                                            anchors.centerIn: parent
                                            columns: 2
                                            spacing: 3
                                            Repeater {
                                                model: 4
                                                delegate: Rectangle {
                                                    width: 5
                                                    height: 5
                                                    radius: 1
                                                    color: modeButton.current ? Core.Theme.accent : Core.Theme.foreground
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: modeArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                Services.LauncherStateService.setViewMode(modelData.mode)
                                                searchField.forceActiveFocus()
                                            }
                                        }
                                        Components.PressBounce { pressed: modeArea.pressed }
                                    }
                                }
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Core.UiStyle.controlHeightLarge
                        orientation: ListView.Horizontal
                        spacing: Core.UiStyle.spacingXs
                        model: root.categories
                        clip: true

                        delegate: Rectangle {
                            required property var modelData
                            width: categoryRow.implicitWidth + Core.UiStyle.spacingMd * 2
                            height: Core.UiStyle.controlHeight
                            radius: Core.UiStyle.radiusControl
                            color: root.category === modelData.name
                                ? Core.Theme.alphaColor(Core.Theme.selected, 0.16)
                                : (categoryArea.containsMouse
                                   ? Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.55)
                                   : "transparent")
                            border.width: Core.UiStyle.borderWidth
                            border.color: root.category === modelData.name
                                ? Core.Theme.alphaColor(Core.Theme.accent, 0.55)
                                : "transparent"

                            RowLayout {
                                id: categoryRow
                                anchors.centerIn: parent
                                spacing: Core.UiStyle.spacingXs
                                IconImage {
                                    Layout.preferredWidth: Core.UiStyle.iconSize
                                    Layout.preferredHeight: Core.UiStyle.iconSize
                                    source: Quickshell.iconPath(modelData.icon, "")
                                }
                                Text {
                                    font.family: Core.Theme.fontFamily
                                    font.pixelSize: Core.UiStyle.fontCaption
                                    text: modelData.name
                                    color: root.category === modelData.name
                                        ? Core.Theme.accent
                                        : Core.Theme.foreground
                                }
                            }
                            MouseArea {
                                id: categoryArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.category = modelData.name
                                    root.selectedIndex = 0
                                    searchField.forceActiveFocus()
                                }
                            }
                            Components.PressBounce { pressed: categoryArea.pressed }
                        }
                    }

                    ListView {
                        id: appList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: !root.gridMode
                        model: root.results
                        currentIndex: root.selectedIndex
                        clip: true
                        spacing: 0

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: Core.UiStyle.grid
                                radius: Core.UiStyle.radiusControl
                                color: Core.Theme.accent
                                opacity: parent.pressed ? 0.9 : 0.42
                            }
                        }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: appList.width
                            height: 48
                            radius: Core.UiStyle.flatRows ? 0 : Core.UiStyle.radiusSurface
                            color: index === root.selectedIndex
                                ? Core.Theme.alphaColor(Core.Theme.selected, 0.11)
                                : (appLaunchArea.containsMouse
                                   ? Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.34)
                                   : "transparent")

                            Rectangle {
                                visible: index === root.selectedIndex && Core.UiStyle.accentMarkerSelection
                                width: 2
                                height: Math.max(16, parent.height - Core.UiStyle.spacingMd * 2)
                                radius: 1
                                color: Core.Theme.accent
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: Core.UiStyle.borderWidth
                                color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.32)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Core.UiStyle.spacingMd
                                anchors.rightMargin: Core.UiStyle.spacingSm
                                spacing: Core.UiStyle.spacingSm

                                IconImage {
                                    Layout.preferredWidth: Core.UiStyle.iconBox
                                    Layout.preferredHeight: Core.UiStyle.iconBox
                                    source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        font.family: Core.Theme.fontFamily
                                        text: modelData.name
                                        color: Core.Theme.foreground
                                        font.pixelSize: Core.UiStyle.fontBody
                                        font.weight: index === root.selectedIndex ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        font.family: Core.Theme.fontFamily
                                        font.pixelSize: Core.UiStyle.fontCaption
                                        text: modelData.comment || root.entryCategory(modelData)
                                        color: Core.Theme.muted
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Text {
                                    font.family: Core.Theme.fontFamily
                                    font.pixelSize: Core.UiStyle.fontCaption
                                    text: Services.LauncherStateService.isFavorite(modelData.id) ? "Unfavorite" : "Favorite"
                                    color: Core.Theme.muted
                                    MouseArea {
                                        id: favoriteArea
                                        anchors.fill: parent
                                        anchors.margins: -Core.UiStyle.spacingXs
                                        onClicked: Services.LauncherStateService.toggleFavorite(modelData.id)
                                    }
                                    Components.PressBounce { pressed: favoriteArea.pressed }
                                }
                            }

                            MouseArea {
                                id: appLaunchArea
                                anchors.fill: parent
                                z: -1
                                hoverEnabled: true
                                onEntered: root.selectedIndex = index
                                onClicked: root.launch(modelData)
                            }
                            Components.PressBounce { pressed: appLaunchArea.pressed }
                        }

                        Text {
                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.UiStyle.fontBody
                            anchors.centerIn: parent
                            visible: appList.count === 0
                            text: "No matching applications"
                            color: Core.Theme.muted
                        }
                    }

                    GridView {
                        id: appGrid
                        readonly property int columns: Math.max(1, Math.floor(width / root.gridCellBase))

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.topMargin: Core.UiStyle.spacingXs
                        visible: root.gridMode
                        model: root.results
                        currentIndex: root.selectedIndex
                        clip: true
                        cellWidth: Math.floor(width / columns)
                        cellHeight: root.gridCellBase

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: Core.UiStyle.grid
                                radius: Core.UiStyle.radiusControl
                                color: Core.Theme.accent
                                opacity: parent.pressed ? 0.9 : 0.42
                            }
                        }

                        delegate: Item {
                            id: gridCell
                            required property var modelData
                            required property int index
                            readonly property bool selected: index === root.selectedIndex
                            readonly property bool lit: gridArea.containsMouse || selected

                            width: appGrid.cellWidth
                            height: appGrid.cellHeight

                            Rectangle {
                                id: gridTile
                                anchors.centerIn: parent
                                width: root.gridTileSize
                                height: root.gridTileSize
                                radius: Math.max(12, Core.Theme.radius + 2)
                                color: gridCell.lit
                                    ? Core.Theme.alphaColor(Core.Theme.surfaceElevated, 0.76)
                                    : "transparent"
                                border.width: gridCell.lit ? Core.Theme.borderWidth : 0
                                border.color: Core.Theme.alphaColor(Core.Theme.accent, gridCell.selected ? 0.82 : 0.42)
                                scale: gridArea.containsMouse && !Core.UiStyle.quietButtons ? 1.06 : 1.0

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Math.round(Core.Theme.animationMs * Core.Theme.motionScale)
                                    }
                                }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Math.round(Core.Theme.animationMs * Core.Theme.motionScale)
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: root.gridIconSize
                                    source: Quickshell.iconPath(gridCell.modelData.icon, "application-x-executable")
                                }

                                Rectangle {
                                    visible: Services.LauncherStateService.isFavorite(gridCell.modelData.id)
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    color: Core.Theme.accent
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: Core.UiStyle.grid
                                }
                            }

                            MouseArea {
                                id: gridArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    root.selectedIndex = gridCell.index
                                    root.showTooltip(gridTile, gridCell.index, gridCell.modelData.name)
                                }
                                onExited: {
                                    if (root.hoverIndex === gridCell.index)
                                        root.hoverLabel = ""
                                }
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton)
                                        Services.LauncherStateService.toggleFavorite(gridCell.modelData.id)
                                    else
                                        root.launch(gridCell.modelData)
                                }
                            }
                            Components.PressBounce {
                                target: gridTile
                                pressed: gridArea.pressed
                            }
                        }

                        Text {
                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.UiStyle.fontBody
                            anchors.centerIn: parent
                            visible: appGrid.count === 0
                            text: "No matching applications"
                            color: Core.Theme.muted
                        }
                    }
                }

                Rectangle {
                    id: gridTooltip
                    visible: root.gridMode && root.hoverLabel.length > 0
                    z: 30
                    radius: Core.UiStyle.radiusControl
                    color: Core.Theme.alphaColor(Core.Theme.surfaceElevated, 1.0)
                    border.width: Core.UiStyle.borderWidth
                    border.color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.80)
                    width: tooltipLabel.implicitWidth + Core.UiStyle.spacingSm * 2
                    height: tooltipLabel.implicitHeight + Core.UiStyle.spacingXs * 2
                    x: Math.max(Core.UiStyle.spacingXs,
                                Math.min(launcherCard.width - width - Core.UiStyle.spacingXs,
                                         root.hoverCenterX - width / 2))
                    y: root.hoverBottomY + Core.UiStyle.spacingXs + height <= root.hoverMaxY
                        ? root.hoverBottomY + Core.UiStyle.spacingXs
                        : root.hoverTopY - height - Core.UiStyle.spacingXs

                    Text {
                        id: tooltipLabel
                        anchors.centerIn: parent
                        text: root.hoverLabel
                        color: Core.Theme.foreground
                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.UiStyle.fontCaption
                    }
                }
            }
        }
    }
}
