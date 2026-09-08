import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core" as Core
import "../services" as Services

PanelWindow {
    id: popup

    property bool menuOpen: false
    property string currentWidget: ""
    property string currentWidgetName: ""
    property var targetScreen: null

    readonly property color insetFill: Core.Theme.alphaColor(
        Core.Theme.surfaceHover,
        Core.UiStyle.flatSurfaces ? 0.34 : 0.58
    )
    readonly property color insetBorder: Core.Theme.alphaColor(
        Core.Theme.barOutlineColor,
        Core.UiStyle.flatSurfaces ? 0.34 : 0.56
    )

    visible: menuOpen
    screen: targetScreen || Quickshell.screens[0]

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    focusable: true
    color: "transparent"

    function close() {
        menuOpen = false
        currentWidget = ""
        currentWidgetName = ""
    }

    function toggle() {
        if (menuOpen) {
            close()
        } else {
            menuOpen = true
        }
    }

    function openTo(kind) {
        const definition = Core.WidgetRegistry.definition(kind)
        menuOpen = true
        currentWidget = kind
        currentWidgetName = definition ? definition.name : kind
    }

    function runQuickAction(action) {
        if (action === "launcher") {
            close()
            Core.InteractiveShellController.launcher("open")
        } else if (action === "monitor") {
            close()
            if (!systemMonitorProcess.running)
                systemMonitorProcess.running = true
        } else if (action === "theme") {
            close()
            if (!themeProcess.running)
                themeProcess.running = true
        } else if (action === "home") {
            close()
            Core.InteractiveShellController.homepage("toggle")
        } else if (action === "lock") {
            close()
            Services.SessionService.lock()
        } else if (action === "session") {
            close()
            Core.InteractiveShellController.drawersOpen("session", "")
        }
    }

    Process {
        id: systemMonitorProcess
        command: [
            "sh", "-lc",
            "if command -v missioncenter >/dev/null 2>&1; then exec missioncenter; "
            + "elif command -v resources >/dev/null 2>&1; then exec resources; "
            + "elif command -v gnome-system-monitor >/dev/null 2>&1; then exec gnome-system-monitor; "
            + "elif command -v plasma-systemmonitor >/dev/null 2>&1; then exec plasma-systemmonitor; "
            + "elif command -v btop >/dev/null 2>&1; then exec kitty --class system-monitor -e btop; "
            + "else exec notify-send 'System monitor' 'Install Mission Center, Resources, or btop'; fi"
        ]
    }

    Process {
        id: themeProcess
        command: ["kitty", "--class", "theme-picker", "-e", "term", "theme"]
    }

    MouseArea {
        id: backdrop
        anchors.fill: parent
        onClicked: popup.close()
    }

    Item {
        anchors.fill: parent
        focus: popup.menuOpen
        Keys.onEscapePressed: popup.close()
    }

    Rectangle {
        id: card
        anchors {
            top: parent.top
            right: parent.right
        }
        anchors.topMargin: Core.Theme.barHeight + Core.UiStyle.spacingMd
        anchors.rightMargin: Core.UiStyle.spacingSm
        width: 340
        implicitHeight: mainCol.implicitHeight + Core.UiStyle.spacing2xl
        color: Core.Theme.surface
        radius: Core.UiStyle.radiusOverlay
        border.width: Core.UiStyle.borderWidth
        border.color: Core.Theme.barOutlineColor

        MouseArea {
            id: cardClickShield
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: mainCol
            anchors.fill: parent
            anchors.margins: Core.UiStyle.spacingMd
            spacing: Core.UiStyle.spacingSm

            RowLayout {
                Layout.fillWidth: true
                spacing: Core.UiStyle.spacingSm
                visible: popup.currentWidget !== ""

                Text {
                    font.family: Core.Theme.fontFamily
                    text: "←"
                    color: Core.Theme.foreground
                    font.pixelSize: Core.UiStyle.iconSize + 3

                    MouseArea {
                        id: backArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.currentWidget = ""
                            popup.currentWidgetName = ""
                        }
                    }
                    PressBounce { pressed: backArea.pressed }
                }

                Text {
                    font.family: Core.Theme.fontFamily
                    text: popup.currentWidgetName
                    color: Core.Theme.foreground
                    font.pixelSize: Core.UiStyle.fontTitle
                    font.bold: true
                }
            }

            ColumnLayout {
                id: overviewCol
                Layout.fillWidth: true
                spacing: Core.UiStyle.spacingSm
                visible: popup.currentWidget === ""

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Core.UiStyle.spacingSm

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Core.UiStyle.spacingXs / 2

                        // Deliberately oversized: the clock is a high-salience desktop affordance.
                        Text {
                            font.family: Core.Theme.fontFamily
                            text: Services.TimeService.timeLong
                            color: Core.Theme.foreground
                            font.pixelSize: 31
                            font.bold: true
                        }

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: Services.TimeService.dateLong
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.fontSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 0
                        Text {
                            font.family: Core.Theme.fontFamily
                            text: {
                                if (!Services.PowerService.available) return "󰁹"
                                if (Services.PowerService.charging) return "󰂄"
                                const p = Services.PowerService.percent
                                if (p >= 90) return "󰁹"
                                if (p >= 70) return "󰂁"
                                if (p >= 50) return "󰁾"
                                if (p >= 30) return "󰁼"
                                if (p >= 10) return "󰁺"
                                return "󰂃"
                            }
                            color: Services.PowerService.percent <= 15 && !Services.PowerService.charging
                                ? Core.Theme.urgent : Core.Theme.foreground
                            font.pixelSize: Core.UiStyle.iconSize + 6
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            font.family: Core.Theme.fontFamily
                            text: Services.PowerService.available ? Services.PowerService.percent + "%" : "--"
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.fontBody
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        Text {
                            font.family: Core.Theme.fontFamily
                            text: Services.NotificationService.dndEnabled
                                ? "󰂛"
                                : (Services.NotificationService.count > 0 ? "󰂚" : "󰂜")
                            color: Services.NotificationService.count > 0
                                ? Core.Theme.accent : Core.Theme.muted
                            font.pixelSize: Core.UiStyle.iconSize + 6
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            font.family: Core.Theme.fontFamily
                            text: Services.NotificationService.count > 0
                                ? Services.NotificationService.count : ""
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.fontBody
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: Core.UiStyle.spacingXs
                    rowSpacing: Core.UiStyle.spacingXs

                    Repeater {
                        model: [
                            { action: "launcher", icon: "󰍉", label: "Apps" },
                            { action: "monitor", icon: "󰍛", label: "Monitor" },
                            { action: "theme", icon: "󰏘", label: "Theme" },
                            { action: "home", icon: "󰋜", label: "Home" },
                            { action: "lock", icon: "󰌾", label: "Lock" },
                            { action: "session", icon: "󰐥", label: "Session" }
                        ]

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: Core.UiStyle.controlHeightLarge
                            radius: Core.UiStyle.radiusControl
                            color: quickActionArea.containsMouse
                                ? Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.62)
                                : popup.insetFill
                            border.width: Core.UiStyle.borderWidth
                            border.color: quickActionArea.containsMouse
                                ? Core.Theme.alphaColor(Core.Theme.accent, 0.52)
                                : popup.insetBorder

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: parent.parent.modelData.icon
                                    color: Core.Theme.foreground
                                    font.family: Core.Theme.fontFamily
                                    font.pixelSize: Core.UiStyle.iconSize + 2
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: parent.parent.modelData.label
                                    color: Core.Theme.muted
                                    font.family: Core.Theme.fontFamily
                                    font.pixelSize: Core.UiStyle.fontCaption
                                }
                            }

                            MouseArea {
                                id: quickActionArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popup.runQuickAction(modelData.action)
                            }
                            PressBounce { pressed: quickActionArea.pressed }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: Core.UiStyle.controlHeightLarge + Core.UiStyle.spacingMd
                    radius: Core.UiStyle.radiusSurface
                    color: popup.insetFill
                    border.width: Core.UiStyle.borderWidth
                    border.color: popup.insetBorder

                    MouseArea {
                        id: systemStatsArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.currentWidget = "system-stats"
                            popup.currentWidgetName = "System"
                        }
                    }
                    PressBounce { pressed: systemStatsArea.pressed }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Core.UiStyle.spacingSm
                        spacing: Core.UiStyle.spacingLg

                        RowLayout {
                            spacing: Core.UiStyle.spacingXs
                            Text {
                                text: "CPU"
                                color: Core.Theme.muted
                                font.pixelSize: Core.UiStyle.fontBody
                            }
                            Text {
                                text: Services.SystemStatsService.cpuPercent + "%"
                                color: Services.SystemStatsService.cpuPercent >= 90
                                    ? Core.Theme.urgent : Core.Theme.foreground
                                font.pixelSize: Core.UiStyle.fontSection
                                font.bold: true
                            }
                        }
                        RowLayout {
                            spacing: Core.UiStyle.spacingXs
                            Text {
                                text: "RAM"
                                color: Core.Theme.muted
                                font.pixelSize: Core.UiStyle.fontBody
                            }
                            Text {
                                text: Services.SystemStatsService.memoryPercent + "%"
                                color: Services.SystemStatsService.memoryPercent >= 90
                                    ? Core.Theme.urgent : Core.Theme.foreground
                                font.pixelSize: Core.UiStyle.fontSection
                                font.bold: true
                            }
                        }
                        RowLayout {
                            spacing: Core.UiStyle.spacingXs
                            Text {
                                text: "DISK"
                                color: Core.Theme.muted
                                font.pixelSize: Core.UiStyle.fontBody
                            }
                            Text {
                                text: Services.SystemStatsService.diskPercent + "%"
                                color: Services.SystemStatsService.diskPercent >= 90
                                    ? Core.Theme.urgent : Core.Theme.foreground
                                font.pixelSize: Core.UiStyle.fontSection
                                font.bold: true
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "›"
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.iconSize + 2
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: mediaRow.implicitHeight + Core.UiStyle.spacingLg
                    radius: Core.UiStyle.radiusSurface
                    color: popup.insetFill
                    border.width: Core.UiStyle.borderWidth
                    border.color: popup.insetBorder
                    visible: Services.MprisService.status !== "Stopped"

                    MouseArea {
                        id: mediaCardArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.currentWidget = "media"
                            popup.currentWidgetName = "Now Playing"
                        }
                    }
                    PressBounce { pressed: mediaCardArea.pressed }

                    RowLayout {
                        id: mediaRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Core.UiStyle.spacingSm
                        spacing: Core.UiStyle.spacingSm

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Core.UiStyle.spacingXs / 2
                            Text {
                                Layout.fillWidth: true
                                text: Services.MprisService.title || "Unknown"
                                color: Core.Theme.foreground
                                font.pixelSize: Core.UiStyle.fontTitle
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: Services.MprisService.artist || "Unknown Artist"
                                color: Core.Theme.muted
                                font.pixelSize: Core.UiStyle.fontSecondary
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: Services.MprisService.status === "Playing" ? "󰏤" : "󰐊"
                            color: Core.Theme.accent
                            font.pixelSize: Core.UiStyle.iconSize + 7
                            MouseArea {
                                id: mpPlayPauseArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Services.MprisService.playPause()
                            }
                            PressBounce { pressed: mpPlayPauseArea.pressed }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: weatherRow.implicitHeight + Core.UiStyle.spacingLg
                    radius: Core.UiStyle.radiusSurface
                    color: popup.insetFill
                    border.width: Core.UiStyle.borderWidth
                    border.color: popup.insetBorder
                    visible: Services.WeatherService.available

                    MouseArea {
                        id: weatherCardArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.currentWidget = "weather"
                            popup.currentWidgetName = "Weather"
                        }
                    }
                    PressBounce { pressed: weatherCardArea.pressed }

                    RowLayout {
                        id: weatherRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Core.UiStyle.spacingSm
                        spacing: Core.UiStyle.spacingSm

                        Text {
                            text: Services.WeatherService.icon || "🌡"
                            font.pixelSize: Core.UiStyle.iconSize + 12
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Core.UiStyle.spacingXs / 2
                            Text {
                                text: Services.WeatherService.temp
                                color: Core.Theme.foreground
                                font.pixelSize: Core.UiStyle.fontTitle + 3
                                font.bold: true
                            }
                            Text {
                                Layout.fillWidth: true
                                text: Services.WeatherService.condition
                                color: Core.Theme.muted
                                font.pixelSize: Core.UiStyle.fontSecondary
                                elide: Text.ElideRight
                            }
                        }
                        Text {
                            text: "›"
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.iconSize + 2
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: networkRow.implicitHeight + Core.UiStyle.spacingLg
                    radius: Core.UiStyle.radiusSurface
                    color: popup.insetFill
                    border.width: Core.UiStyle.borderWidth
                    border.color: popup.insetBorder

                    MouseArea {
                        id: networkCardArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.currentWidget = "network"
                            popup.currentWidgetName = "Network"
                        }
                    }
                    PressBounce { pressed: networkCardArea.pressed }

                    RowLayout {
                        id: networkRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Core.UiStyle.spacingSm
                        spacing: Core.UiStyle.spacingSm

                        Text {
                            text: Services.NetworkService.connected ? "󰤨" : "󰤭"
                            color: Services.NetworkService.connected
                                ? Core.Theme.foreground : Core.Theme.muted
                            font.pixelSize: Core.UiStyle.iconSize + 7
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Core.UiStyle.spacingXs / 2
                            Text {
                                text: Services.NetworkService.connected
                                    ? (Services.NetworkService.ssid || Services.NetworkService.type)
                                    : "Disconnected"
                                color: Services.NetworkService.connected
                                    ? Core.Theme.foreground : Core.Theme.muted
                                font.pixelSize: Core.UiStyle.fontTitle
                                font.bold: true
                            }
                            Text {
                                visible: Services.TailscaleService.connected
                                text: Services.TailscaleService.isMullvad
                                    ? "Mullvad VPN active" : "Tailscale connected"
                                color: Core.Theme.accent
                                font.pixelSize: Core.UiStyle.fontBody
                            }
                        }
                        Text {
                            text: "›"
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.iconSize + 2
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: volRow.implicitHeight + Core.UiStyle.spacingLg
                    radius: Core.UiStyle.radiusSurface
                    color: popup.insetFill
                    border.width: Core.UiStyle.borderWidth
                    border.color: popup.insetBorder

                    RowLayout {
                        id: volRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Core.UiStyle.spacingSm
                        spacing: Core.UiStyle.spacingSm

                        Text {
                            text: Services.AudioService.muted ? "󰝟" : "󰕾"
                            color: Services.AudioService.muted
                                ? Core.Theme.muted : Core.Theme.foreground
                            font.pixelSize: Core.UiStyle.iconSize + 7
                            MouseArea {
                                id: muteToggleArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Services.AudioService.toggleMute()
                            }
                            PressBounce { pressed: muteToggleArea.pressed }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: Core.UiStyle.grid
                            radius: Math.min(Core.UiStyle.radiusControl, height / 2)
                            color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.42)
                            Rectangle {
                                width: parent.width * Services.AudioService.volume / 100
                                height: parent.height
                                radius: parent.radius
                                color: Services.AudioService.muted
                                    ? Core.Theme.muted : Core.Theme.accent
                            }
                        }

                        Text {
                            text: Services.AudioService.volume + "%"
                            color: Core.Theme.foreground
                            font.pixelSize: Core.UiStyle.fontSection
                            font.bold: true
                        }
                    }
                }
            }

            Loader {
                id: panelLoader
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 0
                active: popup.currentWidget !== ""
                visible: active
                source: active
                    ? Qt.resolvedUrl("../widgets/" + popup.currentWidget + "/Panel.qml")
                    : ""
                onStatusChanged: {
                    if (status === Loader.Error)
                        console.warn("Failed to load panel for", popup.currentWidget)
                }
            }
        }
    }
}
