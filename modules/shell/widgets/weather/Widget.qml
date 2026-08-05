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

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: Services.WeatherService.icon || "🌡"
            font.pixelSize: context.variant === "compact" ? 14 : 18
        }

        Text {
            text: Services.WeatherService.temp
            color: Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 12 : 14
            font.bold: true
        }

        Text {
            visible: context.variant !== "compact"
            text: Services.WeatherService.condition
            color: Core.Theme.muted
            font.pixelSize: 11
            elide: Text.ElideRight
            Layout.maximumWidth: 100
        }
    }
}
