import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../core" as Core

Item {
    id: root

    property var context: ({
        variant: "standard",
        settings: ({}),
        locked: false,
        allows: function() { return false }
    })

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: context.variant === "compact" ? 4 : 7

        Repeater {
            model: Hyprland.workspaces

            Rectangle {
                required property var modelData

                visible: modelData.id > 0
                Layout.preferredWidth: visible
                    ? (context.variant === "compact" ? 24 : 34) : 0
                Layout.preferredHeight: visible
                    ? (context.variant === "compact" ? 24 : 34) : 0
                radius: Core.Theme.radius
                color: modelData.focused ? Core.Theme.accent
                    : modelData.active ? Core.Theme.accent2
                    : workspaceMouse.containsMouse ? Core.Theme.surface
                    : "transparent"
                border.width: modelData.focused ? 0 : Core.Theme.borderWidth
                border.color: modelData.active ? Core.Theme.accent2 : Core.Theme.roles.border_normal

                Text {
                    anchors.centerIn: parent
                    text: modelData.name
                    color: modelData.focused ? Core.Theme.background : Core.Theme.foreground
                    font.pixelSize: context.variant === "compact" ? 12 : 14
                    font.bold: modelData.active
                }

                MouseArea {
                    id: workspaceMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: context.allows("workspace.switch")
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: modelData.activate()
                }
            }
        }
    }
}
