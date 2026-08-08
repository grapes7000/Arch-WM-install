import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../components" as Components
import "../../services" as Services

Item {
    id: root

    property var context: ({
        variant: "standard",
        settings: ({}),
        locked: false,
        allows: function() { return false }
    })

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    MouseArea { anchors.fill: parent; z: 10; enabled: context.allows("drawer.open"); cursorShape: Qt.PointingHandCursor; onClicked: context.request("drawer.open", { kind: "notifications", anchorItem: root }) }

    Rectangle {
        visible: context.variant === "compact"
        anchors.centerIn: content
        width: content.width + 10
        height: content.height + 6
        radius: Core.Theme.radius
        color: hoverHandler.hovered
            ? Qt.rgba(Qt.color(Core.Theme.surface).r, Qt.color(Core.Theme.surface).g, Qt.color(Core.Theme.surface).b, 0.5)
            : "transparent"
        border.width: Services.NotificationService.dndEnabled ? 1 : 0
        border.color: Core.Theme.accent
        Behavior on color { ColorAnimation { duration: Core.Theme.animationMs } }
    }
    HoverHandler { id: hoverHandler }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 4

        Text {
            font.family: Core.Theme.fontFamily
            text: Services.NotificationService.dndEnabled ? "󰂛" : (Services.NotificationService.count > 0 ? "󰂚" : "󰂜")
            color: Services.NotificationService.count > 0 ? Core.Theme.accent : Core.Theme.muted
            font.pixelSize: context.variant === "compact" ? 16 : 20

            MouseArea {
                id: dismissArea
                anchors.fill: parent
                enabled: context.allows("notification.dismiss")
                onClicked: Services.NotificationService.dismiss()
            }

            Components.PressBounce { pressed: dismissArea.pressed }
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: Services.NotificationService.count > 0
            text: Services.NotificationService.count
            color: Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 12 : 14
            font.bold: true
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact"
            text: Services.NotificationService.dndEnabled ? "DND" : ""
            color: Core.Theme.muted
            font.pixelSize: 11

            MouseArea {
                id: dndArea
                anchors.fill: parent
                enabled: context.allows("notification.dismiss")
                onClicked: Services.NotificationService.toggleDnd()
            }

            Components.PressBounce { pressed: dndArea.pressed }
        }
    }
}

