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
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Text {
                text: Services.WeatherService.icon || "🌡"
                font.pixelSize: 48
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: Services.WeatherService.temp
                    color: Core.Theme.foreground
                    font.pixelSize: 32
                    font.bold: true
                }

                Text {
                    text: Services.WeatherService.condition
                    color: Core.Theme.muted
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Core.Theme.muted
            opacity: 0.2
        }

        Text {
            visible: !Services.WeatherService.available
            text: "Weather data unavailable"
            color: Core.Theme.muted
            font.pixelSize: 12
        }
    }
}
