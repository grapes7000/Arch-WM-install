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
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Text {
                font.family: Core.Theme.fontFamily
                text: Services.WeatherService.icon || "🌡"
                font.pixelSize: 44
                color: Core.Theme.foreground
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

<<<<<<< Updated upstream
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: Services.WeatherService.available ? Services.WeatherService.temp : "--"
                        color: Core.Theme.foreground
                        font.pixelSize: 30
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 1
                        Text {
                            text: Services.WeatherService.available ? "H " + Services.WeatherService.high : "--"
                            color: Core.Theme.foreground
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: Services.WeatherService.available ? "L " + Services.WeatherService.low : "--"
                            color: Core.Theme.muted
                            font.pixelSize: 11
                        }
                    }
                }

                Text {
                    text: Services.WeatherService.condition || "Unavailable"
=======
                Text {
                    font.family: Core.Theme.fontFamily
                    text: Services.WeatherService.temp
                    color: Core.Theme.foreground
                    font.pixelSize: 32
                    font.bold: true
                }

                Text {
                    font.family: Core.Theme.fontFamily
                    text: Services.WeatherService.condition
>>>>>>> Stashed changes
                    color: Core.Theme.muted
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    visible: Services.WeatherService.available && Services.WeatherService.locationName
                    text: Services.WeatherService.locationName
                    color: Core.Theme.accent
                    font.pixelSize: 10
                    font.bold: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Core.Theme.muted
            opacity: 0.2
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
            font.pixelSize: 12
        }
    }
}

