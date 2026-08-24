import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

Item {
    id: panel
    implicitHeight: layout.implicitHeight

    component StatBar: ColumnLayout {
        property string label: ""
        property int value: 0
        property color barColor: Core.Theme.accent
        spacing: Core.UiStyle.spacingXs

        RowLayout {
            Layout.fillWidth: true
            Text {
                font.family: Core.Theme.fontFamily
                text: label
                color: Core.Theme.muted
                font.pixelSize: Core.UiStyle.fontBody
            }
            Item { Layout.fillWidth: true }
            Text {
                font.family: Core.Theme.fontFamily
                text: value + "%"
                color: value >= 90 ? Core.Theme.urgent : Core.Theme.foreground
                font.pixelSize: Core.UiStyle.fontSection
                font.bold: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: Math.max(2, Core.UiStyle.grid)
            radius: Math.min(Core.UiStyle.radiusControl, height / 2)
            color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.34)

            Rectangle {
                width: parent.width * Math.min(100, Math.max(0, parent.parent.value)) / 100
                height: parent.height
                radius: parent.radius
                color: parent.parent.value >= 90 ? Core.Theme.urgent
                    : parent.parent.value >= 70 ? Core.Theme.accent2
                    : parent.parent.barColor

                Behavior on width {
                    enabled: !Core.UiStyle.motionNone
                    NumberAnimation {
                        duration: Core.UiStyle.motionNormalMs
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Core.UiStyle.spacingLg

        StatBar { label: "CPU"; value: Services.SystemStatsService.cpuPercent; Layout.fillWidth: true }
        StatBar { label: "Memory"; value: Services.SystemStatsService.memoryPercent; Layout.fillWidth: true }
        StatBar { label: "Disk"; value: Services.SystemStatsService.diskPercent; Layout.fillWidth: true }

        Rectangle {
            Layout.fillWidth: true
            height: Core.UiStyle.borderWidth
            color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.42)
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                font.family: Core.Theme.fontFamily
                text: "Uptime"
                color: Core.Theme.muted
                font.pixelSize: Core.UiStyle.fontBody
            }
            Item { Layout.fillWidth: true }
            Text {
                font.family: Core.Theme.fontFamily
                text: Services.SystemStatsService.uptime
                color: Core.Theme.foreground
                font.pixelSize: Core.UiStyle.fontSection
                font.bold: true
            }
        }
    }
}
