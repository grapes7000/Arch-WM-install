import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

Item {
    id: panel
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Core.UiStyle.spacingLg

        RowLayout {
            Layout.fillWidth: true
            spacing: Core.UiStyle.spacingLg

            // Weather icon and temperature remain intentionally prominent.
            Text {
                font.family: Core.Theme.fontFamily
                text: Services.WeatherService.icon || "🌡"
                font.pixelSize: 47
                color: Core.Theme.foreground
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Core.UiStyle.spacingXs

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Core.UiStyle.spacingSm

                    Text {
                        font.family: Core.Theme.fontFamily
                        text: Services.WeatherService.available ? Services.WeatherService.temp : "--"
                        color: Core.Theme.foreground
                        font.pixelSize: 33
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: Math.max(1, Core.UiStyle.spacingXs / 2)
                        Text {
                            font.family: Core.Theme.fontFamily
                            text: Services.WeatherService.available ? "H " + Services.WeatherService.high : "--"
                            color: Core.Theme.foreground
                            font.pixelSize: Core.UiStyle.fontBody
                            font.bold: true
                        }
                        Text {
                            font.family: Core.Theme.fontFamily
                            text: Services.WeatherService.available ? "L " + Services.WeatherService.low : "--"
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.fontBody
                        }
                    }
                }

                Text {
                    font.family: Core.Theme.fontFamily
                    text: Services.WeatherService.condition || "Unavailable"
                    color: Core.Theme.muted
                    font.pixelSize: Core.UiStyle.fontSection
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    visible: Services.WeatherService.available && Services.WeatherService.locationName
                    text: Services.WeatherService.locationName
                    color: Core.Theme.accent
                    font.pixelSize: Core.UiStyle.fontCaption
                    font.bold: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: Core.UiStyle.borderWidth
            color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.42)
        }

        ForecastSection {
            Layout.fillWidth: true
            compact: false
            expand: false
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: !Services.WeatherService.available
            text: "Weather data unavailable"
            color: Core.Theme.muted
            font.pixelSize: Core.UiStyle.fontSection
        }
    }
}
