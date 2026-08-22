import QtQuick
import QtQuick.Layouts
import "../../core" as Core
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

    MouseArea { anchors.fill: parent; z: 10; enabled: context.allows("drawer.open"); cursorShape: Qt.PointingHandCursor; onClicked: context.request("drawer.open", { kind: "network", anchorItem: root }) }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Core.UiStyle.spacingXs

        Text {
            font.family: Core.Theme.fontFamily
            text: {
                if (!Services.NetworkService.connected) return "󰤭"
                if (Services.NetworkService.type === "ethernet") return "󰈀"
                const s = Services.NetworkService.strength
                if (s >= 75) return "󰤨"
                if (s >= 50) return "󰤥"
                if (s >= 25) return "󰤢"
                return "󰤟"
            }
            color: Services.NetworkService.connected ? Core.Theme.foreground : Core.Theme.muted
            font.pixelSize: context.variant === "compact" ? Core.UiStyle.iconSize + 4 : Core.UiStyle.iconSize + 7
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact"
            text: Services.NetworkService.connected
                ? (Services.NetworkService.ssid || Services.NetworkService.type)
                : "Disconnected"
            color: Services.NetworkService.connected ? Core.Theme.foreground : Core.Theme.muted
            font.pixelSize: Core.UiStyle.fontBody
            elide: Text.ElideRight
            Layout.maximumWidth: 100
        }
    }
}
