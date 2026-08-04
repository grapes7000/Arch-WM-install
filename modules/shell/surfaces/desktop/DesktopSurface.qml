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
                right: true
            }
            margins {
                top: Theme.barHeight + Theme.gap
                right: Theme.gap
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
                implicitHeight: desktopColumn.implicitHeight + Theme.gap * 2
                color: Theme.surface
                radius: Theme.radius
                border.width: Theme.borderWidth
                border.color: Theme.accent2

                ColumnLayout {
                    id: desktopColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Theme.gap
                    }
                    spacing: Theme.gap

                    Repeater {
                        model: LayoutService.desktop.regions.top_right || []

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
