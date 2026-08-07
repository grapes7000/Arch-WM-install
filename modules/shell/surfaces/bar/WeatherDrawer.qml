import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

ColumnLayout {
    implicitHeight: 190
    spacing: Core.Theme.gap

    Text { font.family: Core.Theme.fontFamily; text: "Weather"; color: Core.Theme.foreground; font.pixelSize: 18; font.bold: true }
    RowLayout {
        Layout.fillWidth: true
        spacing: Core.Theme.gap * 2
        Text { font.family: Core.Theme.fontFamily; text: Services.WeatherService.icon || "󰖙"; color: Core.Theme.accent; font.pixelSize: 44 }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { font.family: Core.Theme.fontFamily; text: Services.WeatherService.temp; color: Core.Theme.foreground; font.pixelSize: 32; font.bold: true }
            Text { font.family: Core.Theme.fontFamily; Layout.fillWidth: true; text: Services.WeatherService.condition || "Weather data unavailable"; color: Core.Theme.muted; font.pixelSize: 12; elide: Text.ElideRight }
        }
    }
}

