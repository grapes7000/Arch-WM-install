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
        required property string label
        required property int value
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.preferredWidth: 58
            text: parent.label
            color: Theme.muted
            font.pixelSize: 11
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            radius: Theme.radius
            color: Theme.background
            border.width: 1
            border.color: Theme.roles.border_normal

            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, parent.parent.value)) / 100
                height: parent.height
                radius: parent.radius
                color: parent.parent.value >= 90 ? Theme.urgent
                    : parent.parent.value >= 70 ? Theme.accent2 : Theme.accent
            }
        }

        Text {
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
            text: parent.value + "%"
            color: Theme.foreground
            font.pixelSize: 11
        }
    }
}
