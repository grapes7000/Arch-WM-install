import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../core" as Core
import "../../components" as Components
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
                const wallpaper = Core.Theme.data.wallpaper || ""
                if (typeof wallpaper === "string" && wallpaper)
                    return [wallpaper]
                return wallpaper && wallpaper.path ? [wallpaper.path] : []
            }
            readonly property string currentSlide: slides.length > 0
                ? String(slides[Math.min(slideIndex, slides.length - 1)]) : ""
            readonly property bool mediaActive: Services.MprisService.status !== "Stopped"
            readonly property bool heroHasArt: mediaActive && !!Services.MprisService.artUrl
            property bool heroSlideshowEnabled: false
            readonly property bool heroVisible: root.heroSlideshowEnabled ? true : root.heroHasArt
            readonly property string heroSource: root.heroHasArt
                ? Services.MprisService.artUrl
                : (root.heroSlideshowEnabled ? root.currentSlide : "")

            readonly property bool compact: width < 1180 || height < 700
            readonly property real gap: compact ? 8 : Math.max(10, Core.Theme.gap)
            readonly property real leftWidth: compact ? 200 : Math.max(220, Math.min(300, width * 0.18))
            readonly property real rightWidth: compact ? 230 : Math.max(250, Math.min(330, width * 0.21))

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

            property bool anyWindowOpen: false
            property bool hiddenForWindows: false
            property var cpuHistory: []
            property var memoryHistory: []
            property var diskHistory: []

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
                && Core.InteractiveShellController.homepageVisible

            function select(page) {
                selectedPage = selectedPage === page ? "home" : page
            }

            function pageTitle(page) {
                if (!page || page === "home")
                    return "Quick Access"
                return page.charAt(0).toUpperCase() + page.slice(1)
            }

            function pageIcon(page) {
                switch (page) {
                    case "system": return "󰍛"
                    case "network": return "󰖩"
                    case "audio": return "󰕾"
                    case "calendar": return "󰃭"
                    case "media": return "󰎈"
                }
                return "󰆍"
            }

            function panelSourceFor(page) {
                switch (page) {
                    case "network": return Qt.resolvedUrl("../../widgets/network/Panel.qml")
                    case "system": return Qt.resolvedUrl("../../widgets/system-stats/Panel.qml")
                    case "media": return Qt.resolvedUrl("../../widgets/media/Panel.qml")
                    case "audio": return Qt.resolvedUrl("../../widgets/volume/Panel.qml")
                    case "calendar": return Qt.resolvedUrl("../../widgets/clock/Panel.qml")
                }
                return ""
            }

            function appendHistory(values, sample) {
                const next = Array.isArray(values) ? values.slice(-29) : []
                next.push(Math.max(0, Math.min(100, Number(sample) || 0)))
                return next
            }

            Timer {
                id: windowProbe
                interval: 600
                repeat: true
                triggeredOnStart: true
                running: !Services.LockStateService.locked
                onTriggered: {
                    const monitor = Hyprland.monitorFor(root.screen)
                    const workspace = monitor ? monitor.activeWorkspace : Hyprland.focusedWorkspace
                    const open = workspace ? workspace.toplevels.values.length > 0 : false
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

            Timer {
                interval: 2000
                repeat: true
                running: root.visible
                triggeredOnStart: true
                onTriggered: {
                    root.cpuHistory = root.appendHistory(root.cpuHistory, Services.SystemStatsService.cpuPercent)
                    root.memoryHistory = root.appendHistory(root.memoryHistory, Services.SystemStatsService.memoryPercent)
                    root.diskHistory = root.appendHistory(root.diskHistory, Services.SystemStatsService.diskPercent)
                }
            }

            Item {
                id: contentLayer
                anchors.fill: parent
                opacity: root.anyWindowOpen ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Core.Theme.animationMs * 2
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Core.Theme.radius + 10
                    color: Core.Theme.background
                    opacity: 0.86
                    border.width: Core.Theme.borderWidth
                    border.color: Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor
                }

                Image {
                    anchors.fill: parent
                    source: root.heroSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    opacity: status === Image.Ready ? 0.09 : 0
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

                        ProCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.compact ? 108 : 126
                            eyebrow: "Desktop"
                            icon: "󰥔"
                            title: Services.TimeService.timeShort
                            subtitle: Services.TimeService.dateLong
                            statusText: Core.Theme.data.name || "Theme"
                            statusTone: "secondary"
                            heroStyle: true
                            contentPadding: root.compact ? 12 : 14
                        }

                        Repeater {
                            model: [
                                { icon: "󰍛", title: "System", subtitle: "Performance & processes", page: "system" },
                                { icon: "󰖩", title: "Network", subtitle: "Wi-Fi & connectivity", page: "network" },
                                { icon: "󰕾", title: "Audio", subtitle: "Mixer & output devices", page: "audio" },
                                { icon: "󰃭", title: "Calendar", subtitle: "Agenda & upcoming events", page: "calendar" },
                                { icon: "󰎈", title: "Media", subtitle: "Playback & players", page: "media" }
                            ]

                            RailCard {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.compact ? 62 : 72
                                icon: modelData.icon
                                title: modelData.title
                                subtitle: modelData.subtitle
                                active: root.selectedPage === modelData.page
                                onActivated: root.select(modelData.page)
                            }
                        }

                        Item { Layout.fillHeight: true }

                        ProCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.compact ? 165 : 198
                            eyebrow: "Media"
                            icon: "󰎈"
                            title: Services.MprisService.title || "Nothing playing"
                            subtitle: Services.MprisService.artist || "Waiting for a media player"
                            statusText: root.mediaActive ? Services.MprisService.status.toUpperCase() : "IDLE"
                            statusTone: Services.MprisService.status === "Playing" ? "good" : "muted"
                            contentPadding: root.compact ? 11 : 13
                            contentSpacing: 7

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: root.compact ? 38 : 52

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
                                            opacity: 0.88
                                            Behavior on height { NumberAnimation { duration: 70 } }
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 20

                                Text {
                                    text: "󰒮"
                                    color: Services.MprisService.canPrev ? Core.Theme.foreground : Core.Theme.muted
                                    font.pixelSize: 20
                                    opacity: Services.MprisService.canPrev ? 1 : 0.45
                                    MouseArea {
                                        id: hpPrevArea
                                        anchors.fill: parent
                                        enabled: Services.MprisService.canPrev
                                        onClicked: Services.MprisService.previous()
                                    }
                                    Components.PressBounce { pressed: hpPrevArea.pressed }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 38
                                    Layout.preferredHeight: 38
                                    radius: 19
                                    color: Core.Theme.alphaColor(Core.Theme.accent, 0.16)
                                    border.width: 1
                                    border.color: Core.Theme.alphaColor(Core.Theme.accent, 0.36)
                                    Text {
                                        anchors.centerIn: parent
                                        text: Services.MprisService.status === "Playing" ? "󰏤" : "󰐊"
                                        color: Core.Theme.accent
                                        font.pixelSize: 21
                                    }
                                    MouseArea { id: hpPlayPauseArea; anchors.fill: parent; onClicked: Services.MprisService.playPause() }
                                    Components.PressBounce { pressed: hpPlayPauseArea.pressed }
                                }

                                Text {
                                    text: "󰒭"
                                    color: Services.MprisService.canNext ? Core.Theme.foreground : Core.Theme.muted
                                    font.pixelSize: 20
                                    opacity: Services.MprisService.canNext ? 1 : 0.45
                                    MouseArea {
                                        id: hpNextArea
                                        anchors.fill: parent
                                        enabled: Services.MprisService.canNext
                                        onClicked: Services.MprisService.next()
                                    }
                                    Components.PressBounce { pressed: hpNextArea.pressed }
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
                            visible: root.heroVisible
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: root.compact ? 230 : 300
                            clip: true

                            ClippingRectangle {
                                anchors.fill: parent
                                radius: Core.Theme.homepageCardRadius
                                color: Core.Theme.surfaceBase
                                border.width: Core.Theme.borderWidth
                                border.color: Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor

                                Image {
                                    anchors.fill: parent
                                    source: root.heroSource
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: true
                                    opacity: status === Image.Ready ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: Core.Theme.animationMs * 2 } }
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: root.compact ? 84 : 98
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
                                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.76) }
                                    }
                                }

                                RowLayout {
                                    visible: root.heroHasArt
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: root.compact ? 13 : 17
                                    spacing: 10

                                    StatusChip {
                                        text: Services.MprisService.status === "Playing" ? "NOW PLAYING" : "PAUSED"
                                        tone: Services.MprisService.status === "Playing" ? "good" : "muted"
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text {
                                            Layout.fillWidth: true
                                            text: Services.MprisService.title
                                            color: "white"
                                            font.pixelSize: root.compact ? 14 : 16
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: Services.MprisService.artist
                                            color: Qt.rgba(1, 1, 1, 0.72)
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }

                        ProCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: root.compact ? 250 : 295
                            fillAlphaBoost: 0.08
                            eyebrow: root.selectedPage === "home" ? "Workspace hub" : "Detail panel"
                            icon: root.pageIcon(root.selectedPage)
                            title: root.pageTitle(root.selectedPage)
                            subtitle: root.selectedPage === "home"
                                ? "Launch apps, open places, and jump into projects"
                                : "Live controls from the shared shell service"
                            statusText: root.selectedPage === "home" ? "SUPER SPACE" : "LIVE"
                            statusTone: root.selectedPage === "home" ? "secondary" : "good"
                            heroStyle: root.selectedPage === "home"
                            contentPadding: root.compact ? 12 : 16
                            contentSpacing: 9

                            QuickAccessPanel {
                                visible: root.selectedPage === "home"
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                compact: root.compact
                                apps: root.quickAccessApps
                            }

                            PagePanel { page: "network" }
                            PagePanel { page: "system" }
                            PagePanel { page: "media" }
                            PagePanel { page: "audio" }
                            PagePanel { page: "calendar" }
                        }

                        ProCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.compact ? 66 : 76
                            eyebrow: "Workspaces"
                            statusText: "HYPRLAND"
                            statusTone: "muted"
                            contentPadding: 8
                            contentSpacing: 0

                            Loader {
                                id: workspaceStrip
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                source: Qt.resolvedUrl("../../widgets/workspaces/Widget.qml")
                                onLoaded: {
                                    if (!item)
                                        return
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

                        ProCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.compact ? 218 : 258
                            eyebrow: "System"
                            icon: "󰍛"
                            title: "System Overview"
                            subtitle: "Uptime " + Services.SystemStatsService.uptime
                            statusText: Services.SystemStatsService.cpuPercent >= 85 ? "HIGH LOAD" : "STABLE"
                            statusTone: Services.SystemStatsService.cpuPercent >= 85 ? "urgent" : "good"
                            contentPadding: root.compact ? 11 : 13
                            contentSpacing: 7

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 6
                                columnSpacing: 6

                                MetricTile {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredHeight: root.compact ? 66 : 72
                                    label: "CPU"
                                    icon: "󰻠"
                                    value: Services.SystemStatsService.cpuPercent
                                    valueText: Services.SystemStatsService.cpuPercent + "%"
                                }

                                MetricTile {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredHeight: root.compact ? 66 : 72
                                    label: "MEMORY"
                                    icon: "󰘚"
                                    tone: "secondary"
                                    value: Services.SystemStatsService.memoryPercent
                                    valueText: Services.SystemStatsService.memoryPercent + "%"
                                }

                                MetricTile {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.columnSpan: 2
                                    Layout.preferredHeight: root.compact ? 60 : 66
                                    label: "DISK"
                                    icon: "󰋊"
                                    value: Services.SystemStatsService.diskPercent
                                    valueText: Services.SystemStatsService.diskPercent + "%"
                                    detail: "root filesystem"
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                ColumnLayout {
                                    Layout.preferredWidth: 58
                                    spacing: 0
                                    Text { text: "CPU"; color: Core.Theme.foreground; font.pixelSize: 10; font.bold: true }
                                    Text { text: "60 sec"; color: Core.Theme.muted; font.pixelSize: 8 }
                                }
                                Sparkline {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: root.compact ? 28 : 34
                                    samples: root.cpuHistory
                                    lineColor: Qt.color(Core.Theme.accent)
                                }
                            }
                        }

                        ProCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.compact ? 100 : 124
                            eyebrow: "Signal"
                            icon: "󰓃"
                            title: "Audio Visualizer"
                            subtitle: Services.CavaService.available ? "Live spectrum" : "Waiting for Cava"
                            statusText: Services.CavaService.available ? "LIVE" : "IDLE"
                            statusTone: Services.CavaService.available ? "good" : "muted"
                            contentPadding: root.compact ? 10 : 12
                            contentSpacing: 5

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 34
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
                        }

                        ProCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.compact ? 198 : 226
                            eyebrow: "Controls"
                            icon: "󰒓"
                            title: "Quick Controls"
                            subtitle: "Frequently changed shell state"
                            statusText: "ACTIVE"
                            statusTone: "secondary"
                            contentPadding: root.compact ? 10 : 12
                            contentSpacing: 8

                            ControlRow {
                                icon: "󰖩"
                                title: "Wi-Fi"
                                subtitle: !Services.NetworkService.radioEnabled
                                    ? "Off"
                                    : (Services.NetworkService.connected ? "Connected" : "Disconnected")
                                enabledState: Services.NetworkService.radioEnabled
                                onToggled: Services.NetworkService.setWifiRadio(!Services.NetworkService.radioEnabled)
                            }

                            ControlRow {
                                icon: "󰂯"
                                title: "Bluetooth"
                                subtitle: Services.BluetoothService.powered ? "On" : "Off"
                                enabledState: Services.BluetoothService.powered
                                onToggled: Services.BluetoothService.setPower(!Services.BluetoothService.powered)
                            }

                            ControlRow {
                                icon: "󰂛"
                                title: "Do Not Disturb"
                                subtitle: Services.NotificationService.dndEnabled ? "Silencing notifications" : "Notifications enabled"
                                enabledState: Services.NotificationService.dndEnabled
                                onToggled: Services.NotificationService.toggleDnd()
                            }
                        }

                        ProCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: root.compact ? 235 : 270
                            eyebrow: "Forecast"
                            icon: Services.WeatherService.icon || "󰖐"
                            title: Services.WeatherService.available ? Services.WeatherService.temp : "Weather"
                            subtitle: Services.WeatherService.available
                                ? Services.WeatherService.condition + (Services.WeatherService.locationName ? " · " + Services.WeatherService.locationName : "")
                                : "Weather service unavailable"
                            statusText: Services.WeatherService.available ? "LIVE" : "OFFLINE"
                            statusTone: Services.WeatherService.available ? "good" : "muted"
                            heroStyle: true
                            contentPadding: root.compact ? 10 : 12
                            contentSpacing: 7

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                MetricTile {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredHeight: root.compact ? 58 : 64
                                    label: "HIGH"
                                    icon: "󰔄"
                                    valueText: Services.WeatherService.available ? Services.WeatherService.high : "--"
                                    showProgress: false
                                }

                                MetricTile {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredHeight: root.compact ? 58 : 64
                                    label: "LOW"
                                    icon: "󰔃"
                                    tone: "secondary"
                                    valueText: Services.WeatherService.available ? Services.WeatherService.low : "--"
                                    showProgress: false
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

            component ControlRow: Rectangle {
                id: controlRow
                property string icon: ""
                property string title: ""
                property string subtitle: ""
                property bool enabledState: false
                property bool interactive: true
                signal toggled()

                Layout.fillWidth: true
                Layout.preferredHeight: root.compact ? 42 : 46
                radius: 10
                color: Core.Theme.alphaColor(Core.Theme.surfaceElevated, 0.42)
                border.width: 1
                border.color: Core.Theme.alphaColor(Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor, 0.38)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 9
                        color: Core.Theme.alphaColor(controlRow.enabledState ? Core.Theme.accent : Core.Theme.muted, 0.11)
                        Text {
                            anchors.centerIn: parent
                            text: controlRow.icon
                            color: controlRow.enabledState ? Core.Theme.accent : Core.Theme.muted
                            font.pixelSize: 15
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { Layout.fillWidth: true; text: controlRow.title; color: Core.Theme.foreground; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: controlRow.subtitle; color: Core.Theme.muted; font.pixelSize: 8; elide: Text.ElideRight }
                    }

                    Rectangle {
                        width: 34
                        height: 18
                        radius: 9
                        readonly property color mutedTint: Qt.color(Core.Theme.muted)
                        color: controlRow.enabledState
                            ? Core.Theme.accent
                            : Qt.rgba(mutedTint.r, mutedTint.g, mutedTint.b, 0.18)
                        border.width: 1
                        border.color: controlRow.enabledState
                            ? Core.Theme.accent
                            : Qt.rgba(mutedTint.r, mutedTint.g, mutedTint.b, 0.48)

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            anchors.verticalCenter: parent.verticalCenter
                            x: controlRow.enabledState ? parent.width - width - 2 : 2
                            color: controlRow.enabledState ? Core.Theme.background : Core.Theme.muted
                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: toggleArea
                            anchors.fill: parent
                            anchors.margins: -4
                            enabled: controlRow.interactive
                            cursorShape: controlRow.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: controlRow.toggled()
                        }
                        Components.PressBounce { pressed: toggleArea.pressed }
                    }
                }
            }

            component PagePanel: Loader {
                property string page: ""
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: item ? item.implicitHeight : 0
                visible: root.selectedPage === page
                active: visible
                source: active ? root.panelSourceFor(page) : ""
            }

            Timer {
                interval: 30000
                running: root.heroSlideshowEnabled && root.slides.length > 1 && !root.mediaActive
                repeat: true
                onTriggered: root.slideIndex = (root.slideIndex + 1) % root.slides.length
            }
        }
    }
}
