import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../core" as Core
import "../../services" as Services
import "../../components"

Scope {
    id: barScope

    LauncherOverlay {}
<<<<<<< Updated upstream

    function requestFromWidget(capability, payload, screen) {
        return Core.InteractiveShellController.requestFromBar(capability, payload, screen)
    }
=======
    DrawerSurface {}
>>>>>>> Stashed changes

    MenuPopup {
        id: menuPopup
    }

<<<<<<< Updated upstream
    QtObject {
        id: drawerAdapter
        function open(kind, anchorItem, screen) {
            menuPopup.openTo(kind)
            return true
        }
        function close() {
            menuPopup.close()
            return true
        }
=======
    function close() {
        if (menuPopup.menuOpen)
            menuPopup.toggle()
        return true
>>>>>>> Stashed changes
    }

    Binding {
        target: Core.InteractiveShellController
<<<<<<< Updated upstream
        property: "drawerController"
        value: drawerAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }

    Connections {
        target: Services.LockStateService
        function onLockedChanged() {
            if (Services.LockStateService.locked)
                menuPopup.close()
        }
=======
        property: "menuController"
        value: barScope
        restoreMode: Binding.RestoreBindingOrValue
    }

    function requestFromWidget(capability, payload, screen) {
        if (capability === "drawer.open" && menuPopup.menuOpen)
            menuPopup.toggle()
        return Core.InteractiveShellController.requestFromBar(capability, payload, screen)
>>>>>>> Stashed changes
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            margins {
                top: Core.Theme.gap
                left: Core.Theme.gap
                right: Core.Theme.gap
            }

            implicitHeight: Core.Theme.barHeight
            exclusiveZone: Core.Theme.barHeight + Core.Theme.gap * 2
            focusable: false
            color: "transparent"
            visible: !Services.LockStateService.locked

            Rectangle {
                id: background
                anchors.fill: parent
                color: Core.Theme.surface
                radius: Core.Theme.radius
                border.width: Core.Theme.borderWidth
                border.color: Core.Theme.accent2

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Core.Theme.gap
                    spacing: Core.Theme.gap

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
                            spacing: Math.max(4, Math.floor(Core.Theme.gap / 2))

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
                            spacing: Math.max(4, Math.floor(Core.Theme.gap / 2))

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
                            spacing: Math.max(4, Math.floor(Core.Theme.gap / 2))

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
                                    font.family: Core.Theme.fontFamily
                                    id: menuTrigger
                                    anchors.centerIn: parent
                                    text: "󰍜"
                                    color: menuPopup.menuOpen
                                        ? Core.Theme.accent : Core.Theme.foreground
                                    font.pixelSize: 16

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
