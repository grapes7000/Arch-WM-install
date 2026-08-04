import QtQuick
import QtQuick.Layouts
import Quickshell
import ArchWmShell 1.0
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

            implicitHeight: Theme.barHeight
            exclusiveZone: implicitHeight
            color: "transparent"

            Rectangle {
                id: background
                anchors.fill: parent
                anchors.margins: Math.max(2, Math.floor(Theme.gap / 2))
                color: Theme.surface
                radius: Theme.radius
                border.width: Theme.borderWidth
                border.color: Theme.accent2

                RowLayout {
                    id: startRegion
                    anchors {
                        left: parent.left
                        leftMargin: Theme.gap
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Theme.gap

                    Repeater {
                        model: LayoutService.bar.regions.start || []

                        WidgetHost {
                            required property var modelData
                            widgetId: modelData.widget
                            surfaceKind: "bar"
                            instanceId: modelData.instance
                            variant: modelData.variant || "compact"
                            settings: modelData.settings || ({})
                            Layout.preferredWidth: implicitWidth
                            Layout.preferredHeight: background.height - Theme.gap
                        }
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.gap

                    Repeater {
                        model: LayoutService.bar.regions.center || []

                        WidgetHost {
                            required property var modelData
                            widgetId: modelData.widget
                            surfaceKind: "bar"
                            instanceId: modelData.instance
                            variant: modelData.variant || "compact"
                            settings: modelData.settings || ({})
                            Layout.preferredWidth: implicitWidth
                            Layout.preferredHeight: background.height - Theme.gap
                        }
                    }
                }

                RowLayout {
                    anchors {
                        right: parent.right
                        rightMargin: Theme.gap
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Theme.gap

                    Repeater {
                        model: LayoutService.bar.regions.end || []

                        WidgetHost {
                            required property var modelData
                            widgetId: modelData.widget
                            surfaceKind: "bar"
                            instanceId: modelData.instance
                            variant: modelData.variant || "compact"
                            settings: modelData.settings || ({})
                            Layout.preferredWidth: implicitWidth
                            Layout.preferredHeight: background.height - Theme.gap
                        }
                    }
                }
            }
        }
    }
}
