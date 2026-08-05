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
            font.pixelSize: context.variant === "compact" ? 16 : 20
        }

        Text {
            visible: context.variant !== "compact"
            text: Services.NetworkService.connected
                ? (Services.NetworkService.ssid || Services.NetworkService.type)
                : "Disconnected"
            color: Services.NetworkService.connected ? Core.Theme.foreground : Core.Theme.muted
            font.pixelSize: 12
            elide: Text.ElideRight
            Layout.maximumWidth: 100
        }
    }
}
