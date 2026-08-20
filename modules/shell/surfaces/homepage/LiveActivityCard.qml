import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

OrbitCard {
    id: root

    property var cpuHistory: []
    property var memoryHistory: []
    property var diskHistory: []

    readonly property var leadingProcess: Services.SystemStatsService.topProcesses.length > 0
        ? Services.SystemStatsService.topProcesses[0] : null
    readonly property string activityKind: {
        if (Services.SystemStatsService.error)
            return "error"
        if (Services.SystemStatsService.cpuPercent >= 75)
            return "cpu"
        if (Services.SystemStatsService.memoryPercent >= 82)
            return "memory"
        if (Services.SystemStatsService.diskPercent >= 92)
            return "disk"
        if (Services.NetworkService.connecting || Services.NetworkService.scanning)
            return "network"
        if (root.leadingProcess && Number(root.leadingProcess.cpu) >= 12)
            return "process"
        return "steady"
    }
    readonly property string activityTitle: {
        switch (root.activityKind) {
        case "cpu": return "Processor under load"
        case "memory": return "Memory pressure"
        case "disk": return "Storage nearly full"
        case "network": return Services.NetworkService.connecting ? "Joining network" : "Scanning networks"
        case "process": return String(root.leadingProcess.name || "Active process")
        case "error": return "Statistics unavailable"
        default: return "System steady"
        }
    }
    readonly property string activitySubtitle: {
        switch (root.activityKind) {
        case "cpu": return "Current processor utilization"
        case "memory": return "Applications are using most available memory"
        case "disk": return "Root filesystem utilization"
        case "network": return Services.NetworkService.ssid || "Network activity"
        case "process": return "Leading process by CPU activity"
        case "error": return Services.SystemStatsService.error
        default: return Services.NetworkService.connected
            ? "Connected to " + (Services.NetworkService.ssid || Services.NetworkService.type)
            : "No urgent activity"
        }
    }
    readonly property real activityValue: {
        switch (root.activityKind) {
        case "memory": return Services.SystemStatsService.memoryPercent
        case "disk": return Services.SystemStatsService.diskPercent
        case "network": return Services.NetworkService.strength
        default: return Services.SystemStatsService.cpuPercent
        }
    }
    readonly property string activityValueText: {
        if (root.activityKind === "error")
            return "--"
        if (root.activityKind === "network")
            return Services.NetworkService.connecting ? "Connecting" : "Scanning"
        if (root.activityKind === "process")
            return Number(root.leadingProcess.cpu).toFixed(1) + "% CPU"
        return Math.round(root.activityValue) + "%"
    }
    readonly property var activitySamples: root.activityKind === "memory"
        ? root.memoryHistory : (root.activityKind === "disk" ? root.diskHistory : root.cpuHistory)
    readonly property color activityTone: ["cpu", "memory", "disk", "error"].includes(root.activityKind)
        ? Core.Theme.urgent : (root.activityKind === "steady" ? Core.Theme.accent2 : Core.Theme.accent)
    readonly property string activityIcon: {
        switch (root.activityKind) {
        case "cpu": return "󰻠"
        case "memory": return "󰘚"
        case "disk": return "󰋊"
        case "network": return "󰖩"
        case "process": return "󰆍"
        case "error": return "󰅚"
        default: return "󰓃"
        }
    }

    title: "Live Activity"
    subtitle: "Changes with current system load"
    icon: root.activityIcon
    statusText: root.activityKind === "steady" ? "QUIET"
        : (root.activityKind === "error" ? "OFFLINE" : "LIVE")
    toneColor: root.activityTone
    contentPadding: 16
    contentSpacing: 12

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: root.activityTitle
            color: Core.Theme.foreground
            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.shellFontSize + 3
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root.activitySubtitle
            color: Core.Theme.muted
            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.shellFontSize
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: root.activityValueText
                color: root.activityTone
                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.shellFontSize + 9
                font.bold: true
            }

            Rectangle {
                visible: root.activityKind !== "error"
                Layout.fillWidth: true
                Layout.preferredHeight: 5
                radius: 3
                color: Core.Theme.alphaColor(Core.Theme.surfaceOverlay, 0.72)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(100, root.activityValue)) / 100
                    height: parent.height
                    radius: parent.radius
                    color: root.activityTone
                    Behavior on width {
                        NumberAnimation {
                            duration: Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale)
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        Sparkline {
            visible: root.activityKind !== "error"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 54
            samples: root.activitySamples
            lineColor: root.activityTone
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: Services.NetworkService.connected ? "󰖩" : "󰖪"
                color: Services.NetworkService.connected ? Core.Theme.accent : Core.Theme.muted
                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.shellFontSize + 2
            }
            Text {
                Layout.fillWidth: true
                text: Services.NetworkService.connected
                    ? (Services.NetworkService.ssid || "Network connected") : "Network offline"
                color: Core.Theme.muted
                font.family: Core.Theme.fontFamily
                font.pixelSize: Math.max(9, Core.Theme.shellFontSize - 1)
                elide: Text.ElideRight
            }
            Text {
                text: "Up " + Services.SystemStatsService.uptime
                color: Core.Theme.muted
                font.family: Core.Theme.fontFamily
                font.pixelSize: Math.max(9, Core.Theme.shellFontSize - 1)
            }
        }
    }
}
