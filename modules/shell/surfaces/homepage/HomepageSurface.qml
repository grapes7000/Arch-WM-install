import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import "../../core" as Core
import "../../services" as Services
import "../../widgets/weather" as WeatherWidgets

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData

            property string selectedPage: "home"
            property int slideIndex: 0
            property var slides: {
                const configured = Core.Theme.data.wallpapers || []
                if (Array.isArray(configured) && configured.length > 0)
                    return configured
                // theme.json exposes wallpaper as { path, generator }; only
                // fall back to it while the homepage images are loading.
                const wallpaper = Core.Theme.data.wallpaper || ""
                if (typeof wallpaper === "string" && wallpaper)
                    return [wallpaper]
                return wallpaper && wallpaper.path ? [wallpaper.path] : []
            }
            readonly property string currentSlide: slides.length > 0
                ? String(slides[Math.min(slideIndex, slides.length - 1)]) : ""
            readonly property bool mediaActive: Services.MprisService.status !== "Stopped"
            readonly property string heroSource: mediaActive && Services.MprisService.artUrl
                ? Services.MprisService.artUrl : currentSlide
            readonly property bool compact: width < 1180 || height < 700
            readonly property real gap: compact ? 8 : Math.max(10, Core.Theme.gap)
            readonly property real leftWidth: compact ? 220 : Math.max(250, Math.min(310, width * 0.19))
            readonly property real rightWidth: compact ? 240 : Math.max(270, Math.min(330, width * 0.21))

            // Quick Access apps shown on the homepage. Edit this list to change what shows up:
            // - icon: fallback glyph used only if no matching .desktop entry is found
            // - name: label under the icon
            // - command: shell command used both to launch the app and to match it to a .desktop entry
            property var quickAccessApps: [
                { icon: "󰉋", name: "Files", command: "thunar" },
                { icon: "󰆍", name: "Terminal", command: "kitty" },
                { icon: "󰈹", name: "Browser", command: "firefox" },
                { icon: "󰙯", name: "Discord", command: "discord" },
                { icon: "󰓇", name: "Spotify", command: "spotify" },
                { icon: "󰒓", name: "Settings", command: "nwg-look" },
                { icon: "󰓓", name: "Steam", command: "steam" },
                { icon: "󰖲", name: "Hyprland", command: "kitty -e sh -lc 'hyprctl clients; read'" },
                { icon: "󰨞", name: "VS Code", command: "code" },
                { icon: "󱓧", name: "Obsidian", command: "obsidian" }
            ]

            // Hide the dashboard whenever any real window is open so the
            // theme wallpaper shows through instead. Polled by a timer rather
            // than bound to the toplevel model: reacting synchronously to the
            // model's update group crashes this Quickshell version.
            property bool anyWindowOpen: false
            property bool hiddenForWindows: false

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            margins {
                top: Core.Theme.barHeight + root.gap
                bottom: root.gap
                left: root.gap
                right: root.gap
            }
            aboveWindows: false
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            visible: !hiddenForWindows && !Services.LockStateService.locked
            Timer {
                id: windowProbe
                interval: 600
                repeat: true
                triggeredOnStart: true
                running: !Services.LockStateService.locked
                onTriggered: {
                    // Only windows on the workspace currently shown by this
                    // screen should hide the dashboard. Hyprland.toplevels
                    // lists every workspace, so windows elsewhere must not
                    // keep an empty workspace's homepage hidden.
                    const monitor = Hyprland.monitorFor(root.screen)
                    const workspace = monitor
                        ? monitor.activeWorkspace
                        : Hyprland.focusedWorkspace
                    const open = workspace
                        ? workspace.toplevels.values.length > 0
                        : false
                    if (open === root.anyWindowOpen)
                        return
                    root.anyWindowOpen = open
                    if (open) {
                        fadeOutTimer.start()
                    } else {
                        fadeOutTimer.stop()
                        root.hiddenForWindows = false
                    }
                }
            }
            Timer {
                id: fadeOutTimer
                interval: Core.Theme.animationMs * 2
                onTriggered: root.hiddenForWindows = true
            }

            function select(page) {
                selectedPage = selectedPage === page ? "home" : page
            }

            function launch(command) {
                if (!command || launchProcess.running) return
                launchProcess.command = ["sh", "-lc", command]
                launchProcess.running = true
            }

            function desktopIconFor(command) {
                if (!command) return ""
                const bin = command.trim().split(" ")[0].split("/").pop().toLowerCase()
                const entries = [...DesktopEntries.applications.values]
                const match = entries.find(entry => {
                    const id = String(entry.id || "").toLowerCase()
                    const execBin = String(entry.execString || "").trim().split(" ")[0].split("/").pop().toLowerCase()
                    return execBin === bin || id === bin || id === bin + ".desktop"
                })
                return match ? match.icon : ""
            }

            Process {
                id: launchProcess
                onExited: command = []
            }

            // Fades the whole dashboard out when windows are open so the theme
            // wallpaper shows through. PanelWindow has no opacity in this
            // Quickshell version, so the fade lives on a content layer and the
            // window itself is hidden once the fade finishes.
            Item {
                id: contentLayer
                anchors.fill: parent
                opacity: root.anyWindowOpen ? 0 : 1
                Behavior on opacity {
                    NumberAnimation { duration: Core.Theme.animationMs * 2; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Core.Theme.radius + 10
                    color: Core.Theme.background
                    opacity: 0.86
                    border.width: Core.Theme.borderWidth
                    border.color: Core.Theme.accent2
                }

            Image {
                anchors.fill: parent
                source: root.heroSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                opacity: status === Image.Ready ? 0.10 : 0
                scale: 1.08
                Behavior on opacity { NumberAnimation { duration: Core.Theme.animationMs * 2 } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: root.gap
                spacing: root.gap

                ColumnLayout {
                    Layout.minimumWidth: root.leftWidth
                    Layout.preferredWidth: root.leftWidth
                    Layout.maximumWidth: root.leftWidth
                    Layout.fillHeight: true
                    spacing: root.gap

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.compact ? 105 : 128
                        Column {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 5
                            Text {
                                text: Services.TimeService.timeShort
                                color: Core.Theme.foreground
                                font.pixelSize: root.compact ? 30 : 40
                                font.bold: true
                            }
                            Text {
                                text: Services.TimeService.dateLong
                                color: Core.Theme.muted
                                font.pixelSize: 11
                            }
                            Text {
                                text: Core.Theme.data.name || "Current theme"
                                color: Core.Theme.accent
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    Repeater {
                        model: [
                            { icon: "󰍛", title: "System", subtitle: "CPU, memory and system info", page: "system" },
                            { icon: "󰖩", title: "Network", subtitle: "Network & connectivity", page: "network" },
                            { icon: "󰕾", title: "Audio", subtitle: "Audio mixer and devices", page: "audio" },
                            { icon: "󰃭", title: "Calendar", subtitle: "Events and upcoming agenda", page: "calendar" },
                            { icon: "󰎈", title: "Media", subtitle: "Now playing", page: "media" }
                        ]
                        RailCard {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.compact ? 64 : 76
                            icon: modelData.icon
                            title: modelData.title
                            subtitle: modelData.subtitle
                            active: root.selectedPage === modelData.page
                            onActivated: root.select(modelData.page)
                        }
                    }

                    Item { Layout.fillHeight: true }

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.compact ? 170 : 210
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 7

                            Text {
                                text: "Now Playing"
                                color: Core.Theme.accent
                                font.pixelSize: 12
                                font.bold: true
                            }
                            Text {
                                Layout.fillWidth: true
                                text: Services.MprisService.title || "Nothing playing"
                                color: Core.Theme.foreground
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: Services.MprisService.artist || "Your wallpaper slideshow is active"
                                color: Core.Theme.muted
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Row {
                                    anchors.fill: parent
                                    spacing: 2
                                    Repeater {
                                        model: Services.CavaService.bars
                                        Rectangle {
                                            required property real modelData
                                            required property int index
                                            width: Math.max(2, (parent.width - (Services.CavaService.bars.length - 1) * parent.spacing) / Math.max(1, Services.CavaService.bars.length))
                                            height: Math.max(3, parent.height * modelData)
                                            anchors.bottom: parent.bottom
                                            radius: width / 2
                                            color: index % 2 ? Core.Theme.accent2 : Core.Theme.accent
                                            Behavior on height { NumberAnimation { duration: 70 } }
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 22
                                Text { text: "󰒮"; color: Core.Theme.muted; font.pixelSize: 20; MouseArea { anchors.fill: parent; onClicked: Services.MprisService.previous() } }
                                Text { text: Services.MprisService.status === "Playing" ? "󰏤" : "󰐊"; color: Core.Theme.accent; font.pixelSize: 28; MouseArea { anchors.fill: parent; onClicked: Services.MprisService.playPause() } }
                                Text { text: "󰒭"; color: Core.Theme.muted; font.pixelSize: 20; MouseArea { anchors.fill: parent; onClicked: Services.MprisService.next() } }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 360
                    spacing: root.gap

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: root.heroSource
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Core.Theme.animationMs * 2 } }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.04) }
                                GradientStop { position: 0.65; color: Qt.rgba(0, 0, 0, 0.10) }
                                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
                            }
                        }

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: root.compact ? 14 : 22
                            spacing: 10

                            Text {
                                text: root.selectedPage === "home" ? "Quick Access" : root.selectedPage.charAt(0).toUpperCase() + root.selectedPage.slice(1)
                                color: Core.Theme.accent
                                font.pixelSize: 13
                                font.bold: true
                            }

                            GlassCard {
                                visible: root.selectedPage === "home"
                                Layout.fillWidth: true
                                fillAlphaBoost: 0.28
                                implicitHeight: appsLayout.implicitHeight + (root.compact ? 20 : 28)

                                ColumnLayout {
                                    id: appsLayout
                                    anchors.fill: parent
                                    anchors.margins: root.compact ? 10 : 14
                                    spacing: 9

                                    GridLayout {
                                        Layout.fillWidth: true
                                        columns: root.compact ? 4 : 5
                                        rowSpacing: 9
                                        columnSpacing: 9

                                        Repeater {
                                            model: root.quickAccessApps

                                            Item {
                                                id: appTile
                                                required property var modelData
                                                readonly property string desktopIcon: root.desktopIconFor(modelData.command)
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: root.compact ? 68 : 86

                                                Column {
                                                    anchors.centerIn: parent
                                                    spacing: 4
                                                    IconImage {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        visible: appTile.desktopIcon !== ""
                                                        implicitSize: root.compact ? 30 : 40
                                                        source: appTile.desktopIcon !== "" ? Quickshell.iconPath(appTile.desktopIcon, "") : ""
                                                        opacity: appHover.hovered ? 1.0 : 0.9
                                                        scale: appHover.hovered ? 1.08 : 1.0
                                                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                                    }
                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        visible: appTile.desktopIcon === ""
                                                        text: modelData.icon
                                                        color: Core.Theme.accent
                                                        font.pixelSize: root.compact ? 26 : 34
                                                        scale: appHover.hovered ? 1.08 : 1.0
                                                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                                    }
                                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; color: Core.Theme.foreground; font.pixelSize: 9 }
                                                }
                                                HoverHandler { id: appHover; cursorShape: Qt.PointingHandCursor }
                                                TapHandler { onTapped: root.launch(modelData.command) }
                                            }
                                        }
                                    }
                                }
                            }

                            GlassCard {
                                visible: root.selectedPage !== "home"
                                Layout.fillWidth: true
                                fillAlphaBoost: 0.28
                                implicitHeight: panelHostLayout.implicitHeight + (root.compact ? 20 : 32)

                                ColumnLayout {
                                    id: panelHostLayout
                                    anchors.fill: parent
                                    anchors.margins: root.compact ? 10 : 16
                                    spacing: 0

                                    PagePanel { page: "network" }
                                    PagePanel { page: "system" }
                                    PagePanel { page: "media" }
                                    PagePanel { page: "audio" }
                                    PagePanel { page: "calendar" }
                                }
                            }
                        }
                    }

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.compact ? 66 : 80

                        // The same workspaces widget the bar renders: identical
                        // icons, names, focus/active coloring, hover lift, and
                        // click-to-switch behavior. showLabels reveals every
                        // slot name since the strip has room for it.
                        Loader {
                            id: workspaceStrip
                            anchors.fill: parent
                            anchors.margins: 6
                            source: Qt.resolvedUrl("../../widgets/workspaces/Widget.qml")
                            onLoaded: {
                                item.context = {
                                    variant: "standard",
                                    settings: { showLabels: true },
                                    locked: false,
                                    allows: function(capability) {
                                        return capability === "workspace.switch"
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.minimumWidth: root.rightWidth
                    Layout.preferredWidth: root.rightWidth
                    Layout.maximumWidth: root.rightWidth
                    Layout.fillHeight: true
                    spacing: root.gap

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.compact ? 150 : 200
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 10
                            Text { text: "System Overview"; color: Core.Theme.accent; font.bold: true; font.pixelSize: 13 }
                            StatBar { label: "CPU"; value: Services.SystemStatsService.cpuPercent }
                            StatBar { label: "Memory"; value: Services.SystemStatsService.memoryPercent }
                            StatBar { label: "Disk"; value: Services.SystemStatsService.diskPercent }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Uptime"; color: Core.Theme.muted; font.pixelSize: 10 }
                                Item { Layout.fillWidth: true }
                                Text { text: Services.SystemStatsService.uptime; color: Core.Theme.foreground; font.pixelSize: 10; font.bold: true }
                            }
                        }
                    }

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.compact ? 90 : 125
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8
                            Text { text: "Audio Visualizer"; color: Core.Theme.accent; font.bold: true; font.pixelSize: 12 }
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Row {
                                    anchors.fill: parent
                                    spacing: 3
                                    Repeater {
                                        model: Services.CavaService.bars
                                        Rectangle {
                                            required property real modelData
                                            width: Math.max(2, (parent.width - (Services.CavaService.bars.length - 1) * parent.spacing) / Math.max(1, Services.CavaService.bars.length))
                                            height: Math.max(4, parent.height * modelData)
                                            anchors.bottom: parent.bottom
                                            radius: width / 2
                                            color: Core.Theme.accent
                                            Behavior on height { NumberAnimation { duration: 70 } }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.compact ? 140 : 180
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 11
                            Text { text: "Quick Controls"; color: Core.Theme.accent; font.bold: true; font.pixelSize: 12 }
                            ControlRow {
                                icon: "󰖩"; title: "Wi-Fi"
                                subtitle: !Services.NetworkService.radioEnabled ? "Off" : (Services.NetworkService.connected ? "Connected" : "Disconnected")
                                enabledState: Services.NetworkService.radioEnabled
                                onToggled: Services.NetworkService.setWifiRadio(!Services.NetworkService.radioEnabled)
                            }
                            ControlRow {
                                icon: "󰂯"; title: "Bluetooth"
                                subtitle: Services.BluetoothService.powered ? "On" : "Off"
                                enabledState: Services.BluetoothService.powered
                                onToggled: Services.BluetoothService.setPower(!Services.BluetoothService.powered)
                            }
                            ControlRow { icon: "󰖔"; title: "Night Light"; subtitle: "Not available"; enabledState: false; interactive: false }
                            ControlRow {
                                icon: "󰂛"; title: "Do Not Disturb"; subtitle: "Notifications"
                                enabledState: Services.NotificationService.dndEnabled
                                onToggled: Services.NotificationService.toggleDnd()
                            }
                        }
                    }

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: root.compact ? 200 : 300
                        Layout.preferredHeight: root.compact ? 260 : 400
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: root.compact ? 12 : 15
                            spacing: root.compact ? 6 : 9

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Weather"; color: Core.Theme.accent; font.bold: true; font.pixelSize: 12 }
                                Item { Layout.fillWidth: true }
                                Text {
                                    visible: Services.WeatherService.available && Services.WeatherService.locationName
                                    text: Services.WeatherService.locationName
                                    color: Core.Theme.muted
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Text {
                                    text: Services.WeatherService.icon || "󰖐"
                                    color: Core.Theme.foreground
                                    font.pixelSize: root.compact ? 24 : 30
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: Services.WeatherService.available ? Services.WeatherService.temp : "--"
                                        color: Core.Theme.foreground
                                        font.pixelSize: root.compact ? 22 : 28
                                        font.bold: true
                                    }
                                    Text {
                                        text: Services.WeatherService.available ? Services.WeatherService.condition : "Unavailable"
                                        color: Core.Theme.muted
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }
                                ColumnLayout {
                                    spacing: 1
                                    Text {
                                        text: "H " + (Services.WeatherService.available ? Services.WeatherService.high : "--")
                                        color: Core.Theme.foreground
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                    Text {
                                        text: "L " + (Services.WeatherService.available ? Services.WeatherService.low : "--")
                                        color: Core.Theme.muted
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            WeatherWidgets.ForecastSection {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                compact: root.compact
                                expand: true
                            }
                        }
                    }
                }
            }

            }

            component StatBar: ColumnLayout {
                property string label: ""
                property int value: 0
                spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: label; color: Core.Theme.foreground; font.pixelSize: 10 }
                    Item { Layout.fillWidth: true }
                    Text { text: value + "%"; color: Core.Theme.foreground; font.pixelSize: 10; font.bold: true }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Core.Theme.surfaceHover
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(100, value)) / 100
                        height: parent.height
                        radius: parent.radius
                        color: Core.Theme.accent
                        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    }
                }
            }

            component ControlRow: RowLayout {
                id: controlRow
                property string icon: ""
                property string title: ""
                property string subtitle: ""
                property bool enabledState: false
                property bool interactive: true
                signal toggled()
                Layout.fillWidth: true
                spacing: 9
                Text { text: icon; color: Core.Theme.accent; font.pixelSize: 18 }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text { text: title; color: Core.Theme.foreground; font.pixelSize: 10; font.bold: true }
                    Text { text: subtitle; color: Core.Theme.muted; font.pixelSize: 8 }
                }
                Rectangle {
                    width: 34
                    height: 18
                    radius: 9
                    readonly property color mutedTint: Qt.color(Core.Theme.muted)
                    color: enabledState ? Core.Theme.accent : Qt.rgba(mutedTint.r, mutedTint.g, mutedTint.b, 0.22)
                    border.width: 1
                    border.color: enabledState ? Core.Theme.accent : Qt.rgba(mutedTint.r, mutedTint.g, mutedTint.b, 0.6)
                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        anchors.verticalCenter: parent.verticalCenter
                        x: enabledState ? parent.width - width - 2 : 2
                        color: enabledState ? Core.Theme.background : Core.Theme.muted
                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        enabled: controlRow.interactive
                        cursorShape: controlRow.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: controlRow.toggled()
                    }
                }
            }

            // Homepage pages reuse the same shared panels the bar's drawers
            // render, so a page is never a stale summary of its widget.
            function panelSourceFor(page) {
                switch (page) {
                    case "network": return Qt.resolvedUrl("../../widgets/network/Panel.qml")
                    case "system": return Qt.resolvedUrl("../../widgets/system-stats/Panel.qml")
                    case "media": return Qt.resolvedUrl("../../widgets/media/Panel.qml")
                    case "audio": return Qt.resolvedUrl("../../surfaces/bar/AudioDrawer.qml")
                    case "calendar": return Qt.resolvedUrl("../../surfaces/bar/CalendarDrawer.qml")
                }
                return ""
            }

            component PagePanel: Loader {
                property string page: ""
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 0
                visible: root.selectedPage === page
                active: visible
                source: active ? root.panelSourceFor(page) : ""
            }

            Timer {
                interval: 30000
                running: root.slides.length > 1 && !root.mediaActive
                repeat: true
                onTriggered: root.slideIndex = (root.slideIndex + 1) % root.slides.length
            }
        }
    }
}