import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

ColumnLayout {
    implicitHeight: 360
    spacing: Core.Theme.gap

    component Meter: RowLayout {
        id: meter
        required property string label
        required property real value
        Layout.fillWidth: true
        Text { font.family: Core.Theme.fontFamily; Layout.preferredWidth: 58; text: parent.label; color: Core.Theme.muted; font.pixelSize: 11 }
        Rectangle {
            Layout.fillWidth: true; height: 8; radius: 4; color: Core.Theme.background
            Rectangle { width: parent.width * Math.max(0, Math.min(100, meter.value)) / 100; height: parent.height; radius: parent.radius; color: meter.value >= 90 ? Core.Theme.urgent : Core.Theme.accent }
        }
        Text { font.family: Core.Theme.fontFamily; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight; text: Math.round(parent.value) + "%"; color: Core.Theme.foreground; font.pixelSize: 10 }
    }

    Text { font.family: Core.Theme.fontFamily; text: "System"; color: Core.Theme.foreground; font.pixelSize: 18; font.bold: true }
    Meter { label: "CPU"; value: Services.SystemStatsService.cpuPercent }
    Meter { label: "Memory"; value: Services.SystemStatsService.memoryPercent }
    Meter { label: "Disk"; value: Services.SystemStatsService.diskPercent }
    RowLayout {
        Layout.fillWidth: true
        Text { font.family: Core.Theme.fontFamily; text: "Uptime"; color: Core.Theme.muted; font.pixelSize: 11 }
        Item { Layout.fillWidth: true }
        Text { font.family: Core.Theme.fontFamily; text: Services.SystemStatsService.uptime; color: Core.Theme.foreground; font.pixelSize: 11; font.bold: true }
        Text { font.family: Core.Theme.fontFamily; visible: Services.SystemStatsService.temperature > 0; text: Math.round(Services.SystemStatsService.temperature) + "°C"; color: Core.Theme.accent; font.pixelSize: 11 }
    }
    Text { font.family: Core.Theme.fontFamily; text: "Top processes"; color: Core.Theme.muted; font.pixelSize: 10; font.bold: true }
    Repeater {
        model: Services.SystemStatsService.topProcesses
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Text { font.family: Core.Theme.fontFamily; Layout.fillWidth: true; text: modelData.name || modelData.command || "Process"; color: Core.Theme.foreground; elide: Text.ElideRight; font.pixelSize: 11 }
            Text { font.family: Core.Theme.fontFamily; text: (modelData.cpu || 0) + "%"; color: Core.Theme.muted; font.pixelSize: 10 }
        }
    }
}

