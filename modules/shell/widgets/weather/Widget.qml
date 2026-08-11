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

    MouseArea { anchors.fill: parent; z: 10; enabled: context.allows("drawer.open"); cursorShape: Qt.PointingHandCursor; onClicked: context.request("drawer.open", { kind: "weather", anchorItem: root }) }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 4
        visible: Services.WeatherService.available

        Text {
            font.family: Core.Theme.fontFamily
            text: Services.WeatherService.icon || "🌡"
            font.pixelSize: context.variant === "compact" ? 17 : 21
        }

        Text {
            font.family: Core.Theme.fontFamily
            text: Services.WeatherService.temp
            color: Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 15 : 17
            font.bold: true
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact"
            text: Services.WeatherService.condition
            color: Core.Theme.muted
            font.pixelSize: 14
            elide: Text.ElideRight
            Layout.maximumWidth: 100
        }
    }
}

