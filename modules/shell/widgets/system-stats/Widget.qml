import QtQuick
import QtQuick.Layouts
import ArchWmShell 1.0

Item {
    id: root

    required property var context

    implicitWidth: context.variant === "compact" ? compactText.implicitWidth : 280
    implicitHeight: context.variant === "compact" ? compactText.implicitHeight
        : context.variant === "standard" ? 92 : 170

    Text {
        id: compactText
        anchors.centerIn: parent
        visible: context.variant === "compact"
        text: "CPU " + SystemStatsService.cpuPercent + "%  "
            + "MEM " + SystemStatsService.memoryPercent + "%  "
            + "DSK " + SystemStatsService.diskPercent + "%"
        color: Theme.foreground
        font.pixelSize: 12
        font.bold: true
    }

    ColumnLayout {
        anchors.fill: parent
        visible: context.variant !== "compact"
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "SYSTEM"
            color: Theme.accent
            font.pixelSize: context.variant === "expanded" ? 18 : 14
            font.bold: true
        }

        StatRow {
            label: "CPU"
            value: SystemStatsService.cpuPercent
        }
        StatRow {
            label: "MEMORY"
            value: SystemStatsService.memoryPercent
        }
        StatRow {
            label: "DISK"
            value: SystemStatsService.diskPercent
        }

        Text {
            Layout.fillWidth: true
            visible: context.variant === "expanded"
            text: "UPTIME  " + SystemStatsService.uptime
            color: Theme.muted
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
            color: Theme.muted
            font.pixelSize: 11
            font.bold: true
        }

        Rectangle {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            radius: Theme.radius
            color: Theme.background
            border.width: 1
            border.color: Theme.roles.border_normal

            Rectangle {
                width: track.width * Math.max(0, Math.min(100, row.value)) / 100
                height: track.height
                radius: track.radius
                color: row.value >= 90 ? Theme.urgent
                    : row.value >= 70 ? Theme.accent2 : Theme.accent
            }
        }

        Text {
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
            text: row.value + "%"
            color: Theme.foreground
            font.pixelSize: 11
        }
    }
}
