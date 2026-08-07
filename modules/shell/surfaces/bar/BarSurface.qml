import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../core" as Core
import "../../services" as Services
import "../../components"

Scope {
    id: barScope

    LauncherOverlay {}
    DrawerSurface {}

    MenuPopup {
        id: menuPopup
    }

    function close() {
        if (menuPopup.menuOpen)
            menuPopup.toggle()
        return true
    }

    Binding {
        target: Core.InteractiveShellController
        property: "menuController"
        value: barScope
        restoreMode: Binding.RestoreBindingOrValue
    }

    function requestFromWidget(capability, payload, screen) {
        if (capability === "drawer.open" && menuPopup.menuOpen)
            menuPopup.toggle()
        return Core.InteractiveShellController.requestFromBar(capability, payload, screen)
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData

            anchors {
                top: Core.Theme.barPosition === "top"
                bottom: Core.Theme.barPosition === "bottom"
                left: true
                right: true
            }
            margins {
                top: Core.Theme.barPosition === "top" ? Core.Theme.barOuterMargin : 0
                bottom: Core.Theme.barPosition === "bottom" ? Core.Theme.barOuterMargin : 0
                left: Core.Theme.barOuterMargin
                right: Core.Theme.barOuterMargin
            }

            implicitHeight: Core.Theme.barHeight
            exclusiveZone: Core.Theme.barHeight + Core.Theme.barOuterMargin * 2
            focusable: false
            color: "transparent"
            visible: !Services.LockStateService.locked

            Rectangle {
                id: background
                anchors.fill: parent
                color: Core.Theme.alphaColor(Core.Theme.barSurfaceColor, Core.Theme.barOpacity)
                radius: Core.Theme.barRadius
                border.width: Core.Theme.barOutlineWidth
                border.color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, Core.Theme.barOutlineOpacity)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Core.Theme.barPadding
                    spacing: Core.Theme.barWidgetSpacing

                    Item {
                        id: startCell
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        RowLayout {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: Core.Theme.barWidgetSpacing

                            Repeater {
                                model: Services.LayoutService.bar.regions.start || []

                                WidgetHost {
                                    required property var modelData
                                    widgetId: modelData.widget
                                    surfaceKind: "bar"
                                    instanceId: modelData.instance
                                    variant: modelData.variant || "compact"
                                    settings: modelData.settings || ({})
                                    locked: Services.LockStateService.locked
                                    requestHandler: function(capability, payload) {
                                        return barScope.requestFromWidget(capability, payload, root.screen)
                                    }
                                    Layout.preferredWidth: implicitWidth
                                    Layout.preferredHeight: implicitHeight
                                }
                            }
                        }
                    }

                    Item {
                        id: centerCell
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Core.Theme.barWidgetSpacing

                            Repeater {
                                model: Services.LayoutService.bar.regions.center || []

                                WidgetHost {
                                    required property var modelData
                                    widgetId: modelData.widget
                                    surfaceKind: "bar"
                                    instanceId: modelData.instance
                                    variant: modelData.variant || "compact"
                                    settings: modelData.settings || ({})
                                    locked: Services.LockStateService.locked
                                    requestHandler: function(capability, payload) {
                                        return barScope.requestFromWidget(capability, payload, root.screen)
                                    }
                                    Layout.preferredWidth: implicitWidth
                                    Layout.preferredHeight: implicitHeight
                                }
                            }
                        }
                    }

                    Item {
                        id: endCell
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        RowLayout {
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: Core.Theme.barWidgetSpacing

                            Repeater {
                                model: Services.LayoutService.bar.regions.end || []

                                WidgetHost {
                                    required property var modelData
                                    widgetId: modelData.widget
                                    surfaceKind: "bar"
                                    instanceId: modelData.instance
                                    variant: modelData.variant || "compact"
                                    settings: modelData.settings || ({})
                                    locked: Services.LockStateService.locked
                                    requestHandler: function(capability, payload) {
                                        return barScope.requestFromWidget(capability, payload, root.screen)
                                    }
                                    Layout.preferredWidth: implicitWidth
                                    Layout.preferredHeight: implicitHeight
                                }
                            }

                            Item {
                                Layout.preferredWidth: menuTrigger.implicitWidth + 8
                                Layout.fillHeight: true

                                Text {
                                    id: menuTrigger
                                    anchors.centerIn: parent
                                    font.family: Core.Theme.fontFamily
                                    text: "󰍜"
                                    color: menuPopup.menuOpen ? Core.Theme.accent : Core.Theme.foreground
                                    font.pixelSize: Core.Theme.barIconSize

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (menuPopup.menuOpen
                                                    || Core.InteractiveShellController.prepareMenuOpen())
                                                menuPopup.toggle()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
