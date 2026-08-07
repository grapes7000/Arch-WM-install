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

    implicitWidth: pill.horizontalPadding * 2 + content.implicitWidth
    implicitHeight: pill.verticalPadding * 2 + content.implicitHeight

    visible: Services.WeatherService.available

    Components.BarPill {
        id: pill
        anchors.fill: parent
        clickable: context.allows("drawer.open")
        onClicked: context.request("drawer.open", { kind: "weather", anchorItem: root })
    }

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

