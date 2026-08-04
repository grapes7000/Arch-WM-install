import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../core" as Core
import "../../services" as Services
import "../../components"

Scope {
    Variants {
        variants: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: Core.Theme.barHeight
            exclusiveZone: implicitHeight
            color: "transparent"

            Rectangle {
                id: background
                anchors.fill: parent
                anchors.margins: Math.max(2, Math.floor(Core.Theme.gap / 2))
                color: Core.Theme.surface
                radius: Core.Theme.radius
                border.width: Core.Theme.borderWidth
                border.color: Core.Theme.accent2

                RowLayout {
                    id: startRegion
                    anchors {
                        left: parent.left
                        leftMargin: Core.Theme.gap
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Core.Theme.gap

                    Repeater {
                        model: Services.LayoutService.bar.regions.start || []

                        WidgetHost {
                            required property var modelData
                            widgetId: modelData.widget
                            surfaceKind: "bar"
                            instanceId: modelData.instance
                            variant: modelData.variant || "compact"
                            settings: modelData.settings || ({})
                            Layout.preferredWidth: implicitWidth
                            Layout.preferredHeight: background.height - Core.Theme.gap
                        }
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Core.Theme.gap

                    Repeater {
                        model: Services.LayoutService.bar.regions.center || []

                        WidgetHost {
                            required property var modelData
                            widgetId: modelData.widget
                            surfaceKind: "bar"
                            instanceId: modelData.instance
                            variant: modelData.variant || "compact"
                            settings: modelData.settings || ({})
                            Layout.preferredWidth: implicitWidth
                            Layout.preferredHeight: background.height - Core.Theme.gap
                        }
                    }
                }

                RowLayout {
                    anchors {
                        right: parent.right
                        rightMargin: Core.Theme.gap
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Core.Theme.gap

                    Repeater {
                        model: Services.LayoutService.bar.regions.end || []

                        WidgetHost {
                            required property var modelData
                            widgetId: modelData.widget
                            surfaceKind: "bar"
                            instanceId: modelData.instance
                            variant: modelData.variant || "compact"
                            settings: modelData.settings || ({})
                            Layout.preferredWidth: implicitWidth
                            Layout.preferredHeight: background.height - Core.Theme.gap
                        }
                    }
                }
            }
        }
    }
}
