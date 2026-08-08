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

    MouseArea { anchors.fill: parent; z: 10; enabled: context.allows("drawer.open"); cursorShape: Qt.PointingHandCursor; onClicked: context.request("drawer.open", { kind: "battery", anchorItem: root }) }

    Rectangle {
        visible: context.variant === "compact"
        anchors.centerIn: content
        width: content.width + 10
        height: content.height + 6
        radius: Core.Theme.radius
        color: hoverHandler.hovered
            ? Qt.rgba(Qt.color(Core.Theme.surface).r, Qt.color(Core.Theme.surface).g, Qt.color(Core.Theme.surface).b, 0.5)
            : "transparent"
        border.width: (Services.PowerService.charging
            || (Services.PowerService.percent <= 15 && !Services.PowerService.charging)) ? 1 : 0
        border.color: Services.PowerService.percent <= 15 && !Services.PowerService.charging
            ? Core.Theme.urgent : Core.Theme.accent
        Behavior on color { ColorAnimation { duration: Core.Theme.animationMs } }
    }
    HoverHandler { id: hoverHandler }

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

