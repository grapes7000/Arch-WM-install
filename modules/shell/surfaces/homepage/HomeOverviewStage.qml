import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

Item {
    id: root

    implicitHeight: homeLayout.implicitHeight

    ColumnLayout {
        id: homeLayout
        anchors.fill: parent
        spacing: 18

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: "Desktop Pulse"
                color: Core.Theme.foreground
                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.shellFontSize + 3
                font.bold: true
            }
            Text {
                Layout.fillWidth: true
                text: "Useful state without covering the wallpaper"
                color: Core.Theme.muted
                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.shellFontSize
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 18

            EmbeddedMetric {
                Layout.fillWidth: true
                icon: "󰖩"
                label: "Network"
                valueText: Services.NetworkService.connected
                    ? (Services.NetworkService.ssid || "Connected") : "Offline"
                value: Services.NetworkService.strength
                showProgress: Services.NetworkService.type === "wifi"
            }
            EmbeddedMetric {
                Layout.fillWidth: true
                icon: Services.WeatherService.icon || "󰖐"
                label: "Outside"
                valueText: Services.WeatherService.available
                    ? Services.WeatherService.temp : "--"
                showProgress: false
                toneColor: Core.Theme.accent2
            }
            EmbeddedMetric {
                Layout.fillWidth: true
                icon: "󰔛"
                label: "Uptime"
                valueText: Services.SystemStatsService.uptime
                showProgress: false
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 150
            radius: Math.max(12, Core.Theme.homepageCardRadius - 3)
            color: Core.Theme.alphaColor(Core.Theme.surfaceOverlay, 0.30)
            border.width: Core.Theme.borderWidth
            border.color: Core.Theme.alphaColor(
                Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor, 0.34)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Text {
                    text: "Active processes"
                    color: Core.Theme.foreground
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.shellFontSize
                    font.bold: true
                }

                Repeater {
                    model: Services.SystemStatsService.topProcesses.slice(0, 3)

                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: Core.Theme.foreground
                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.Theme.shellFontSize
                            elide: Text.ElideRight
                        }
                        Text {
                            text: Number(modelData.cpu).toFixed(1) + "% CPU"
                            color: Core.Theme.muted
                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Math.max(9, Core.Theme.shellFontSize - 1)
                        }
                    }
                }

                Text {
                    visible: Services.SystemStatsService.topProcesses.length === 0
                    text: "Waiting for system activity"
                    color: Core.Theme.muted
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.shellFontSize
                }
            }
        }
    }
}
