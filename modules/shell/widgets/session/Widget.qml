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
        spacing: context.variant === "compact" ? 4 : 8

        Text {
            text: "⏻"
            color: Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 16 : 20

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.lock()
            }
        }

        Text {
            visible: context.variant !== "compact"
            text: "󰍃"
            color: Core.Theme.foreground
            font.pixelSize: 18

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.logout()
            }
        }

        Text {
            visible: context.variant !== "compact"
            text: "󰤄"
            color: Core.Theme.foreground
            font.pixelSize: 18

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.suspend()
            }
        }

        Text {
            visible: context.variant !== "compact"
            text: "󰜉"
            color: Core.Theme.foreground
            font.pixelSize: 18

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.reboot()
            }
        }

        Text {
            visible: context.variant !== "compact"
            text: "󰐥"
            color: Core.Theme.urgent
            font.pixelSize: 18

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.poweroff()
            }
        }
    }
}
