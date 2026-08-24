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
        spacing: Core.UiStyle.spacingSm

        Components.TintedCard {
            visible: Services.PowerService.available
            Layout.fillWidth: true
            implicitHeight: mainCol.implicitHeight + Core.UiStyle.spacing2xl
            active: Services.PowerService.charging
            tintColor: (Services.PowerService.percent <= 15 && !Services.PowerService.charging)
                ? Core.Theme.urgent : Core.Theme.accent

            ColumnLayout {
                id: mainCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Core.UiStyle.spacingMd
                spacing: Core.UiStyle.spacingSm

                RowLayout {
                    spacing: Core.UiStyle.spacingMd

                    Components.ProgressRing {
                        percent: Math.max(0, Services.PowerService.percent) / 100
                        ringColor: (Services.PowerService.percent <= 15 && !Services.PowerService.charging)
                            ? Core.Theme.urgent : Core.Theme.accent
                        label: Services.PowerService.percent + "%"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Core.UiStyle.spacingXs / 2

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: "Battery"
                            color: Core.Theme.foreground
                            font.pixelSize: Core.UiStyle.fontTitle
                            font.bold: true
                        }

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: Services.PowerService.charging ? "Charging" : "On battery"
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.fontBody
                        }
                    }

                    Components.StatusPill {
                        active: Services.PowerService.charging || Services.PowerService.percent >= 100
                        activeLabel: Services.PowerService.percent >= 100 ? "FULL" : "CHARGING"
                        pulse: Services.PowerService.charging && Services.PowerService.percent < 100
                            && Core.UiStyle.motionPlayful
                    }
                }

                Rectangle {
                    visible: Services.PowerService.timeRemaining !== ""
                    Layout.fillWidth: true
                    implicitHeight: timeRow.implicitHeight + Core.UiStyle.spacingSm
                    radius: Core.UiStyle.radiusControl
                    color: Core.Theme.alphaColor(Core.Theme.surfaceHover, Core.UiStyle.flatSurfaces ? 0.30 : 0.52)
                    border.width: Core.UiStyle.borderWidth
                    border.color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, Core.UiStyle.flatSurfaces ? 0.30 : 0.50)

                    RowLayout {
                        id: timeRow
                        anchors.centerIn: parent
                        spacing: Core.UiStyle.spacingXl

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: "󰥔 " + Services.PowerService.timeRemaining
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.fontBody
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
