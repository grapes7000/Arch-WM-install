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

    MouseArea { anchors.fill: parent; z: 10; enabled: context.allows("drawer.open"); cursorShape: Qt.PointingHandCursor; onClicked: context.request("drawer.open", { kind: "audio", anchorItem: root }) }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 4

        Text {
            font.family: Core.Theme.fontFamily
            text: {
                if (Services.AudioService.muted) return "󰝟"
                const v = Services.AudioService.volume
                if (v >= 66) return "󰕾"
                if (v >= 33) return "󰖀"
                return "󰕿"
            }
            color: Services.AudioService.muted ? Core.Theme.muted : Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 16 : 20
        }

        Text {
            font.family: Core.Theme.fontFamily
            text: Services.AudioService.volume + "%"
            color: Services.AudioService.muted ? Core.Theme.muted : Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 12 : 14
            font.bold: true
        }
    }
}

