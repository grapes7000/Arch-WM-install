import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

Item {
    id: root

    property var context: ({
        variant: "standard",
        settings: ({}),
        locked: false,
        allows: function() { return false }
    })

    implicitWidth: context.variant === "compact" ? compactText.implicitWidth : 280
    implicitHeight: context.variant === "compact" ? compactText.implicitHeight
        : context.variant === "standard" ? 92 : 170

    Text {
        id: compactText
        anchors.centerIn: parent
        visible: context.variant === "compact"
        text: "CPU " + Services.SystemStatsService.cpuPercent + "%  ·  RAM "
            + Services.SystemStatsService.memoryPercent + "%"
        color: Core.Theme.foreground
        font.pixelSize: 11
        font.bold: true
    }

    ColumnLayout {
        anchors.fill: parent
        visible: context.variant !== "compact"
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "SYSTEM"
            color: Core.Theme.accent
            font.pixelSize: context.variant === "expanded" ? 18 : 14
            font.bold: true
        }

        StatRow {
            label: "CPU"
            value: Services.SystemStatsService.cpuPercent
        }
        StatRow {
            label: "MEMORY"
            value: Services.SystemStatsService.memoryPercent
        }
        StatRow {
            label: "DISK"
            value: Services.SystemStatsService.diskPercent
        }

        Text {
            Layout.fillWidth: true
            visible: context.variant === "expanded"
            text: "UPTIME  " + Services.SystemStatsService.uptime
            color: Core.Theme.muted
            font.pixelSize: 13
        }
    }

    component StatRow: RowLayout {
        id: row
        required property string label
        required property int value
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.preferredWidth: 58
            text: row.label
            color: Core.Theme.muted
            font.pixelSize: 11
            font.bold: true
        }

        Rectangle {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            radius: Core.Theme.radius
            color: Core.Theme.background
            border.width: 1
            border.color: Core.Theme.roles.border_normal

            Rectangle {
                width: track.width * Math.max(0, Math.min(100, row.value)) / 100
                height: track.height
                radius: track.radius
                color: row.value >= 90 ? Core.Theme.urgent
                    : row.value >= 70 ? Core.Theme.accent2 : Core.Theme.accent
            }
        }

        Text {
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
            text: row.value + "%"
            color: Core.Theme.foreground
            font.pixelSize: 11
        }
    }
}
