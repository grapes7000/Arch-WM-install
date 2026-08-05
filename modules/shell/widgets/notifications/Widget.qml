import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

Item {
    id: root

    required property var context

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: Services.NotificationService.dndEnabled ? "󰂛" : (Services.NotificationService.count > 0 ? "󰂚" : "󰂜")
            color: Services.NotificationService.count > 0 ? Core.Theme.accent : Core.Theme.muted
            font.pixelSize: context.variant === "compact" ? 16 : 20

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("notification.dismiss")
                onClicked: Services.NotificationService.dismiss()
            }
        }

        Text {
            visible: Services.NotificationService.count > 0
            text: Services.NotificationService.count
            color: Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 12 : 14
            font.bold: true
        }

        Text {
            visible: context.variant !== "compact"
            text: Services.NotificationService.dndEnabled ? "DND" : ""
            color: Core.Theme.muted
            font.pixelSize: 11

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("notification.dismiss")
                onClicked: Services.NotificationService.toggleDnd()
            }
        }
    }
}
