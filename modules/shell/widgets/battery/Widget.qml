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

    implicitWidth: content.visible ? content.implicitWidth : 0
    implicitHeight: content.visible ? content.implicitHeight : 0

    MouseArea { anchors.fill: parent; z: 10; enabled: context.allows("drawer.open"); cursorShape: Qt.PointingHandCursor; onClicked: context.request("drawer.open", { kind: "battery", anchorItem: root }) }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 4
        visible: Services.PowerService.available

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
            color: Services.PowerService.charging
                ? Core.Theme.accent
                : (Services.PowerService.percent <= 15 ? Core.Theme.urgent : Core.Theme.foreground)
            font.pixelSize: context.variant === "compact" ? 19 : 23
        }

        Text {
            font.family: Core.Theme.fontFamily
            text: Services.PowerService.percent + "%"
            color: Services.PowerService.charging
                ? Core.Theme.accent
                : (Services.PowerService.percent <= 15 ? Core.Theme.urgent : Core.Theme.foreground)
            font.pixelSize: context.variant === "compact" ? 15 : 17
            font.bold: true
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact" && Services.PowerService.timeRemaining !== ""
            text: Services.PowerService.timeRemaining
            color: Core.Theme.muted
            font.pixelSize: 14
        }
    }
}

