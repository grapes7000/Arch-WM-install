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
                right: true
            }
            margins {
                top: Core.Theme.barHeight + Core.Theme.gap
                right: Core.Theme.gap
            }

            implicitWidth: 360
            implicitHeight: panel.implicitHeight
            aboveWindows: false
            focusable: false
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            Rectangle {
                id: panel
                width: parent.width
                implicitHeight: desktopColumn.implicitHeight + Core.Theme.gap * 2
                color: Core.Theme.surface
                radius: Core.Theme.radius
                border.width: Core.Theme.borderWidth
                border.color: Core.Theme.accent2

                ColumnLayout {
                    id: desktopColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Core.Theme.gap
                    }
                    spacing: Core.Theme.gap

                    Repeater {
                        model: Services.LayoutService.desktop.regions.top_right || []

                        WidgetHost {
                            required property var modelData
                            widgetId: modelData.widget
                            surfaceKind: "desktop"
                            instanceId: modelData.instance
                            variant: modelData.variant || "standard"
                            settings: modelData.settings || ({})
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                        }
                    }
                }
            }
        }
    }
}
