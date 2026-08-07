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

    MouseArea { anchors.fill: parent; z: 10; enabled: context.allows("drawer.open"); cursorShape: Qt.PointingHandCursor; onClicked: context.request("drawer.open", { kind: "session", anchorItem: root }) }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: context.variant === "compact" ? 4 : 8

        Text {
            font.family: Core.Theme.fontFamily
            text: "⏻"
            color: Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 16 : 20

            Components.PressBounce {}

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.lock()
            }
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact"
            text: "󰍃"
            color: Core.Theme.foreground
            font.pixelSize: 18

            Components.PressBounce {}

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.logout()
            }
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact"
            text: "󰤄"
            color: Core.Theme.foreground
            font.pixelSize: 18

            Components.PressBounce {}

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.suspend()
            }
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact"
            text: "󰜉"
            color: Core.Theme.foreground
            font.pixelSize: 18

            Components.PressBounce {}

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.reboot()
            }
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact"
            text: "󰐥"
            color: Core.Theme.urgent
            font.pixelSize: 18

            Components.PressBounce {}

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.poweroff()
            }
        }
    }
}

