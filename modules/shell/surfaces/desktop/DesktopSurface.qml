import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../core" as Core
import "../../services" as Services
import "../../components"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData

            anchors {
                top: true
                right: true
            }
            margins {
                top: Core.Theme.barHeight + Core.Theme.gap * 3
                right: Core.Theme.gap
            }

            implicitWidth: 340
            implicitHeight: desktopColumn.implicitHeight + Core.Theme.gap * 2
            aboveWindows: false
            focusable: false
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            visible: (Services.LayoutService.desktop.regions.top_right || []).length > 0

            Rectangle {
                anchors.fill: parent
                color: Core.Theme.surface
                radius: Core.Theme.radius
                border.width: Core.Theme.borderWidth
                border.color: Core.Theme.accent2

                ColumnLayout {
                    id: desktopColumn
                    anchors.fill: parent
                    anchors.margins: Core.Theme.gap
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
