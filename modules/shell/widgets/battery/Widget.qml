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

    visible: Services.PowerService.available

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 4

        Text {
            font.family: Core.Theme.fontFamily
            text: {
                const p = Services.PowerService.percent
                if (Services.PowerService.charging) return "󰂄"
                if (p >= 90) return "󰁹"
                if (p >= 70) return "󰂀"
                if (p >= 50) return "󰁾"
                if (p >= 30) return "󰁼"
                if (p >= 10) return "󰁺"
                return "󰂃"
            }
            color: Services.PowerService.percent <= 15 && !Services.PowerService.charging
                ? Core.Theme.urgent : Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 16 : 20
        }

        Text {
            font.family: Core.Theme.fontFamily
            text: Services.PowerService.percent + "%"
            color: Services.PowerService.percent <= 15 && !Services.PowerService.charging
                ? Core.Theme.urgent : Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 12 : 14
            font.bold: true
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact" && Services.PowerService.timeRemaining !== ""
            text: Services.PowerService.timeRemaining
            color: Core.Theme.muted
            font.pixelSize: 11
        }
    }
}

