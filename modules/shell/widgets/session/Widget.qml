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

    implicitWidth: pill.horizontalPadding * 2 + content.implicitWidth
    implicitHeight: pill.verticalPadding * 2 + content.implicitHeight

    Components.BarPill {
        id: pill
        z: 10
        anchors.fill: parent
        clickable: context.allows("drawer.open")
        onClicked: context.request("drawer.open", { kind: "session", anchorItem: root })
    }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: context.variant === "compact" ? 4 : 8

        Text {
            font.family: Core.Theme.fontFamily
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
            font.family: Core.Theme.fontFamily
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
            font.family: Core.Theme.fontFamily
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
            font.family: Core.Theme.fontFamily
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
            font.family: Core.Theme.fontFamily
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

