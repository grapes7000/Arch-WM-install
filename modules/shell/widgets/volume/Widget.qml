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
                if (Services.AudioService.muted) return "󰝟"
                const v = Services.AudioService.volume
                if (v >= 66) return "󰕾"
                if (v >= 33) return "󰖀"
                return "󰕿"
            }
            color: Services.AudioService.muted ? Core.Theme.muted : Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 16 : 20

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("audio.control")
                onClicked: Services.AudioService.toggleMute()
            }
        }

        Text {
            text: Services.AudioService.volume + "%"
            color: Services.AudioService.muted ? Core.Theme.muted : Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 12 : 14
            font.bold: true
        }
    }
}
