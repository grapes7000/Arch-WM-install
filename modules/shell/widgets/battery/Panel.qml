import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components

Item {
    id: panel

    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        Components.TintedCard {
            visible: Services.PowerService.available
            Layout.fillWidth: true
            implicitHeight: mainCol.implicitHeight + 24
            active: Services.PowerService.charging
            tintColor: (Services.PowerService.percent <= 15 && !Services.PowerService.charging)
                ? Core.Theme.urgent : Core.Theme.accent

            ColumnLayout {
                id: mainCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    spacing: 12

                    Components.ProgressRing {
                        percent: Math.max(0, Services.PowerService.percent) / 100
                        ringColor: (Services.PowerService.percent <= 15 && !Services.PowerService.charging)
                            ? Core.Theme.urgent : Core.Theme.accent
                        label: Services.PowerService.percent + "%"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: "Battery"
                            color: Core.Theme.foreground
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: Services.PowerService.charging ? "Charging" : "On battery"
                            color: Core.Theme.muted
                            font.pixelSize: 10
                        }
                    }

                    Components.StatusPill {
                        active: Services.PowerService.charging || Services.PowerService.percent >= 100
                        activeLabel: Services.PowerService.percent >= 100 ? "FULL" : "CHARGING"
                        pulse: Services.PowerService.charging && Services.PowerService.percent < 100
                    }
                }

                Rectangle {
                    visible: Services.PowerService.timeRemaining !== ""
                    Layout.fillWidth: true
                    implicitHeight: timeRow.implicitHeight + 8
                    radius: 999
                    color: Qt.rgba(Qt.color(Core.Theme.foreground).r,
                        Qt.color(Core.Theme.foreground).g,
                        Qt.color(Core.Theme.foreground).b, 0.04)
                    border.width: 1
                    border.color: Qt.rgba(Qt.color(Core.Theme.foreground).r,
                        Qt.color(Core.Theme.foreground).g,
                        Qt.color(Core.Theme.foreground).b, 0.06)

                    RowLayout {
                        id: timeRow
                        anchors.centerIn: parent
                        spacing: 20

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: "󰥔 " + Services.PowerService.timeRemaining
                            color: Core.Theme.muted
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        Components.EmptyState {
            visible: !Services.PowerService.available
            Layout.fillWidth: true
            icon: "󰂑"
            message: "No battery detected"
        }
    }
}
