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
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Text { font.family: Core.Theme.fontFamily; text: label; color: Core.Theme.muted; font.pixelSize: 11 }
            Item { Layout.fillWidth: true }
            Text {
                font.family: Core.Theme.fontFamily
                text: value + "%"
                color: value >= 90 ? Core.Theme.urgent : Core.Theme.foreground
                font.pixelSize: 12; font.bold: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.1)

            Rectangle {
                width: parent.width * Math.min(100, Math.max(0, parent.parent.value)) / 100
                height: parent.height
                radius: parent.radius
                color: parent.parent.value >= 90 ? Core.Theme.urgent
                    : parent.parent.value >= 70 ? Core.Theme.accent2
                    : parent.parent.barColor

                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
            }
        }
    }

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 16

        StatBar { label: "CPU"; value: Services.SystemStatsService.cpuPercent; Layout.fillWidth: true }
        StatBar { label: "Memory"; value: Services.SystemStatsService.memoryPercent; Layout.fillWidth: true }
        StatBar { label: "Disk"; value: Services.SystemStatsService.diskPercent; Layout.fillWidth: true }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Core.Theme.muted
            opacity: 0.2
        }

        RowLayout {
            Layout.fillWidth: true
            Text { font.family: Core.Theme.fontFamily; text: "Uptime"; color: Core.Theme.muted; font.pixelSize: 11 }
            Item { Layout.fillWidth: true }
            Text {
                font.family: Core.Theme.fontFamily
                text: Services.SystemStatsService.uptime
                color: Core.Theme.foreground
                font.pixelSize: 12; font.bold: true
            }
        }
    }
}

