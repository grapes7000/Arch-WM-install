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

    Rectangle {
        visible: context.variant === "compact"
        anchors.centerIn: content
        width: content.width + 10
        height: content.height + 6
        radius: Core.Theme.radius
        color: hoverHandler.hovered
            ? Qt.rgba(Qt.color(Core.Theme.surface).r, Qt.color(Core.Theme.surface).g, Qt.color(Core.Theme.surface).b, 0.5)
            : "transparent"
        Behavior on color { ColorAnimation { duration: Core.Theme.animationMs } }
    }
    HoverHandler { id: hoverHandler }

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
                id: lockArea
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.lock()
            }

            Components.PressBounce { pressed: lockArea.pressed }
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact"
            text: "󰍃"
            color: Core.Theme.foreground
            font.pixelSize: 18

            MouseArea {
                id: logoutArea
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.logout()
            }

            Components.PressBounce { pressed: logoutArea.pressed }
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact"
            text: "󰤄"
            color: Core.Theme.foreground
            font.pixelSize: 18

            MouseArea {
                id: suspendArea
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.suspend()
            }

            Components.PressBounce { pressed: suspendArea.pressed }
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact"
            text: "󰜉"
            color: Core.Theme.foreground
            font.pixelSize: 18

            MouseArea {
                id: rebootArea
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.reboot()
            }

            Components.PressBounce { pressed: rebootArea.pressed }
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact"
            text: "󰐥"
            color: Core.Theme.urgent
            font.pixelSize: 18

            MouseArea {
                id: poweroffArea
                anchors.fill: parent
                enabled: context.allows("session.lock")
                onClicked: Services.SessionService.poweroff()
            }

            Components.PressBounce { pressed: poweroffArea.pressed }
        }
    }
}

