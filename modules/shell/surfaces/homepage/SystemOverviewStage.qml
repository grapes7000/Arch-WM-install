import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

Item {
    id: root

    property var cpuHistory: []
    property var memoryHistory: []

    implicitHeight: overview.implicitHeight

    ColumnLayout {
        id: overview
        anchors.fill: parent
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "System Overview"
                color: Core.Theme.foreground
                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.shellFontSize + 3
                font.bold: true
            }

            Text {
                text: "Uptime  " + Services.SystemStatsService.uptime
                color: Core.Theme.muted
                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.shellFontSize
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            EmbeddedMetric {
                Layout.fillWidth: true
                icon: "󰻠"
                label: "CPU"
                valueText: Services.SystemStatsService.cpuPercent + "%"
                value: Services.SystemStatsService.cpuPercent
                toneColor: Services.SystemStatsService.cpuPercent >= 85
                    ? Core.Theme.urgent : Core.Theme.accent
            }

            EmbeddedMetric {
                Layout.fillWidth: true
                icon: "󰘚"
                label: "Memory"
                valueText: Services.SystemStatsService.memoryPercent + "%"
                value: Services.SystemStatsService.memoryPercent
                toneColor: Services.SystemStatsService.memoryPercent >= 88
                    ? Core.Theme.urgent : Core.Theme.accent2
            }

            EmbeddedMetric {
                Layout.fillWidth: true
                icon: "󰋊"
                label: "Disk"
                valueText: Services.SystemStatsService.diskPercent + "%"
                value: Services.SystemStatsService.diskPercent
                toneColor: Services.SystemStatsService.diskPercent >= 92
                    ? Core.Theme.urgent : Core.Theme.accent
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 180
            radius: Math.max(12, Core.Theme.homepageCardRadius - 3)
            color: Core.Theme.alphaColor(Core.Theme.surfaceOverlay, 0.30)
            border.width: Core.Theme.borderWidth
            border.color: Core.Theme.alphaColor(
                Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor, 0.34)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    Text {
                        text: "Performance"
                        color: Core.Theme.foreground
                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.Theme.shellFontSize
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Legend { label: "CPU"; toneColor: Core.Theme.accent }
                    Legend { label: "Memory"; toneColor: Core.Theme.accent2 }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 130

                    Sparkline {
                        anchors.fill: parent
                        samples: root.cpuHistory
                        lineColor: Qt.color(Core.Theme.accent)
                    }
                    Sparkline {
                        anchors.fill: parent
                        samples: root.memoryHistory
                        lineColor: Qt.color(Core.Theme.accent2)
                        fillArea: false
                    }
                }
            }
        }
    }

    component Legend: RowLayout {
        required property string label
        required property color toneColor
        spacing: 5
        Rectangle { width: 7; height: 7; radius: 4; color: parent.toneColor }
        Text {
            text: parent.label
            color: Core.Theme.muted
            font.family: Core.Theme.fontFamily
            font.pixelSize: Math.max(9, Core.Theme.shellFontSize - 1)
        }
    }
}
