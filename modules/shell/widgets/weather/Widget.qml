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

    visible: Services.WeatherService.available

    MouseArea { anchors.fill: parent; z: 10; enabled: context.allows("drawer.open"); cursorShape: Qt.PointingHandCursor; onClicked: context.request("drawer.open", { kind: "weather", anchorItem: root }) }

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
        spacing: 4

        Text {
            font.family: Core.Theme.fontFamily
            text: Services.WeatherService.icon || "🌡"
            font.pixelSize: context.variant === "compact" ? 14 : 18
        }

        Text {
            font.family: Core.Theme.fontFamily
            text: Services.WeatherService.temp
            color: Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 12 : 14
            font.bold: true
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact"
            text: Services.WeatherService.condition
            color: Core.Theme.muted
            font.pixelSize: 11
            elide: Text.ElideRight
            Layout.maximumWidth: 100
        }
    }
}

