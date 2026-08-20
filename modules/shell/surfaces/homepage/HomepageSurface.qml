import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../core" as Core
import "../../services" as Services

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData

            property string selectedPage: "system"
            property bool anyWindowOpen: false
            property bool hiddenForWindows: false
            property var cpuHistory: []
            property var memoryHistory: []
            property var diskHistory: []

            readonly property bool compact: width < 1400 || height < 760
            readonly property real outerMargin: compact ? 16 : 24
            readonly property real clusterHeight: Math.min(height - outerMargin * 2,
                compact ? 680 : 840)
            readonly property real homeWidth: compact ? 620 : 720
            readonly property real homeHeight: compact
                ? Math.min(540, clusterHeight - 140) : 650
            readonly property real sideGap: compact ? 80 : 112
            readonly property real sideWidth: compact ? 310 : 340
            readonly property real clusterWidth: homeWidth + sideGap + sideWidth
            readonly property real sideTop: compact ? 52 : 90
            readonly property real mediaHeight: compact ? 180 : 195
            readonly property real activityTop: sideTop + mediaHeight + (compact ? 14 : 16)
            readonly property real activityHeight: compact ? 220 : 235
            readonly property real appClusterTop: activityTop + activityHeight
                + (compact ? 20 : 24)
            readonly property int surfacePadding: compact ? 18 : 24

            property var fallbackApps: [
                { icon: "󰆍", name: "Terminal", command: "kitty" },
                { icon: "󰈹", name: "Firefox", command: "firefox" },
                { icon: "󰉋", name: "Files", command: "thunar" },
                { icon: "󰨞", name: "VS Code", command: "code" },
                { icon: "󰙯", name: "Discord", command: "discord" },
                { icon: "󰓇", name: "Spotify", command: "spotify" }
            ]

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            margins {
                top: Core.Theme.barHeight + Core.Theme.gap
                bottom: Core.Theme.gap
                left: Core.Theme.gap
                right: Core.Theme.gap
            }
            aboveWindows: false
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            visible: !hiddenForWindows && !Services.LockStateService.locked
                && Core.InteractiveShellController.homepageVisible

            function panelSourceFor(page) {
                switch (page) {
                case "network": return Qt.resolvedUrl("../../widgets/network/Panel.qml")
                case "audio": return Qt.resolvedUrl("../../widgets/volume/Panel.qml")
                case "calendar": return Qt.resolvedUrl("../../widgets/clock/Panel.qml")
                case "media": return Qt.resolvedUrl("../../widgets/media/Panel.qml")
                default: return ""
                }
            }

            function appendHistory(values, sample) {
                const next = Array.isArray(values) ? values.slice(-39) : []
                next.push(Math.max(0, Math.min(100, Number(sample) || 0)))
                return next
            }

            function greeting() {
                const hour = Services.TimeService.date.getHours()
                if (hour < 12)
                    return "Good morning"
                if (hour < 18)
                    return "Good afternoon"
                return "Good evening"
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
                    root.cpuHistory = root.appendHistory(root.cpuHistory,
                        Services.SystemStatsService.cpuPercent)
                    root.memoryHistory = root.appendHistory(root.memoryHistory,
                        Services.SystemStatsService.memoryPercent)
                    root.diskHistory = root.appendHistory(root.diskHistory,
                        Services.SystemStatsService.diskPercent)
                }
            }

            Item {
                id: contentLayer
                anchors.fill: parent
                opacity: root.anyWindowOpen ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Math.round(Core.Theme.animationMs * 2
                            * Core.Theme.motionScale)
                        easing.type: Easing.OutCubic
                    }
                }

                Item {
                    id: orbit
                    width: Math.min(root.clusterWidth, contentLayer.width - root.outerMargin * 2)
                    height: Math.min(root.clusterHeight, contentLayer.height - root.outerMargin * 2)
                    anchors.centerIn: parent

                    GlassCard {
                        id: homeSurface
                        x: 0
                        y: 0
                        width: Math.min(root.homeWidth, orbit.width * 0.64)
                        height: root.homeHeight
                        fillAlphaBoost: -0.10
                        angledShadow: true
                        superDraggable: true
                        assemblyOrder: 0
                        assemblyDirection: "top"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: root.surfacePadding
                            spacing: root.compact ? 12 : 16

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        Layout.fillWidth: true
                                        text: root.greeting() + ", " + (Core.Theme.data.name || "desktop")
                                        color: Core.Theme.foreground
                                        font.family: Core.Theme.fontFamily
                                        font.pixelSize: Core.Theme.shellFontSize + 3
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: Services.TimeService.timeShort + "  ·  " + Services.TimeService.dateLong
                                        color: Core.Theme.muted
                                        font.family: Core.Theme.fontFamily
                                        font.pixelSize: Core.Theme.shellFontSize
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Rectangle {
                                id: searchSurface
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.compact ? 44 : 50
                                radius: Math.max(10, Core.Theme.homepageCardRadius - 4)
                                color: Core.Theme.alphaColor(Core.Theme.surfaceOverlay,
                                    searchHover.hovered ? 0.54 : 0.36)
                                border.width: Core.Theme.borderWidth
                                border.color: Core.Theme.alphaColor(
                                    searchHover.hovered ? Core.Theme.accent
                                    : (Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor),
                                    searchHover.hovered ? 0.62 : 0.36)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 10
                                    Text {
                                        text: "󰍉"
                                        color: searchHover.hovered ? Core.Theme.accent : Core.Theme.muted
                                        font.family: Core.Theme.fontFamily
                                        font.pixelSize: Core.Theme.shellFontSize + 4
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Search apps and files"
                                        color: Core.Theme.muted
                                        font.family: Core.Theme.fontFamily
                                        font.pixelSize: Core.Theme.shellFontSize + 1
                                    }
                                    Text {
                                        text: "SUPER  SPACE"
                                        color: Core.Theme.muted
                                        font.family: Core.Theme.fontFamily
                                        font.pixelSize: Math.max(9, Core.Theme.shellFontSize - 1)
                                    }
                                }

                                HoverHandler { id: searchHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    onTapped: Core.InteractiveShellController.launcher("open")
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Repeater {
                                    model: [
                                        { key: "home", icon: "󰋜", label: "Home" },
                                        { key: "system", icon: "󰍛", label: "System" },
                                        { key: "network", icon: "󰖩", label: "Network" },
                                        { key: "audio", icon: "󰕾", label: "Audio" },
                                        { key: "calendar", icon: "󰃭", label: "Calendar" },
                                        { key: "media", icon: "󰎈", label: "Media" }
                                    ]

                                    SectionToggle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        icon: modelData.icon
                                        label: modelData.label
                                        active: root.selectedPage === modelData.key
                                        onActivated: root.selectedPage = modelData.key
                                    }
                                }
                            }

                            Item {
                                id: detailStage
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                HomeOverviewStage {
                                    anchors.fill: parent
                                    visible: root.selectedPage === "home"
                                }

                                SystemOverviewStage {
                                    anchors.fill: parent
                                    visible: root.selectedPage === "system"
                                    cpuHistory: root.cpuHistory
                                    memoryHistory: root.memoryHistory
                                }

                                Flickable {
                                    id: panelViewport
                                    anchors.fill: parent
                                    visible: !["home", "system"].includes(root.selectedPage)
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    contentWidth: width
                                    contentHeight: panelLoader.height

                                    Loader {
                                        id: panelLoader
                                        width: panelViewport.width
                                        height: Math.max(panelViewport.height,
                                            item ? item.implicitHeight : 0)
                                        source: panelViewport.visible
                                            ? root.panelSourceFor(root.selectedPage) : ""
                                        onLoaded: {
                                            if (item)
                                                item.width = width
                                        }
                                        onWidthChanged: {
                                            if (item)
                                                item.width = width
                                        }
                                    }
                                }
                            }
                        }
                    }

                    NowPlayingCard {
                        x: homeSurface.width + root.sideGap
                        y: root.sideTop
                        width: root.sideWidth
                        height: root.mediaHeight
                        angledShadow: true
                        superDraggable: true
                        assemblyOrder: 1
                        assemblyDirection: "right"
                    }

                    LiveActivityCard {
                        x: homeSurface.width + root.sideGap
                        y: root.activityTop
                        width: root.sideWidth
                        height: root.activityHeight
                        cpuHistory: root.cpuHistory
                        memoryHistory: root.memoryHistory
                        diskHistory: root.diskHistory
                        angledShadow: true
                        superDraggable: true
                        assemblyOrder: 2
                        assemblyDirection: "right"
                    }

                    FloatingAppCluster {
                        x: Math.min(homeSurface.width + root.sideGap,
                            orbit.width - width)
                        y: root.appClusterTop
                        width: 246
                        height: 156
                        z: 0
                        fallbackApps: root.fallbackApps
                    }

                    GlassCard {
                        id: workspacePill
                        x: (homeSurface.width - width) / 2
                        y: homeSurface.height + (root.compact ? 24 : 28)
                        width: root.compact ? 400 : 440
                        height: 54
                        fillAlphaBoost: -0.06
                        angledShadow: true
                        superDraggable: true
                        assemblyOrder: 3
                        assemblyDirection: "bottom"

                        Loader {
                            anchors.fill: parent
                            anchors.margins: 6
                            source: Qt.resolvedUrl("../../widgets/workspaces/Widget.qml")
                            onLoaded: {
                                if (!item)
                                    return
                                item.context = {
                                    variant: "compact",
                                    settings: { showLabels: false },
                                    locked: false,
                                    allows: function(capability) {
                                        return capability === "workspace.switch"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
