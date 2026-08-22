import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../core" as Core
import "../../services" as Services
import "../../components"

Scope {
    id: barScope

    LauncherOverlay {}
    DrawerSurface {}

    MenuPopup { id: menuPopup }

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
            readonly property bool isPrimary: Quickshell.screens.length === 0
                || root.screen === Quickshell.screens[0]
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
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: root.isPrimary ? "arch-wm:bar" : "arch-wm:bar-secondary"

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
                        clip: false

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
                        clip: false

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
                                    Layout.preferredHeight: modelData.widget === "clock"
                                        ? Math.max(implicitHeight, Core.Theme.barHeight - Core.Theme.barPadding * 2 - 2)
                                        : implicitHeight
                                }
                            }
                        }
                    }

                    Item {
                        id: endCell
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: false

                        RowLayout {
                            anchors {
                                right: parent.right
                                rightMargin: Core.UiStyle.spacingXs / 2
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: Core.Theme.barWidgetSpacing

                            Repeater {
                                model: (Services.LayoutService.bar.regions.end || [])
                                    .filter(function(entry) { return entry.instance !== "session-main" })
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

                            PillBox {
                                id: homepageTrigger
                                active: Core.InteractiveShellController.homepageVisible
                                Layout.preferredWidth: Core.Theme.barPillMinWidth
                                Layout.preferredHeight: Core.UiStyle.controlHeightCompact

                                Text {
                                    anchors.centerIn: parent
                                    font.family: Core.Theme.fontFamily
                                    text: "󰋜"
                                    color: Core.InteractiveShellController.homepageVisible
                                        ? Core.Theme.accent : Core.Theme.muted
                                    font.pixelSize: Core.Theme.barIconSize
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Core.InteractiveShellController.homepage("toggle")
                                }
                            }

                            PillBox {
                                id: menuTrigger
                                active: menuPopup.menuOpen
                                Layout.preferredWidth: Core.Theme.barPillMinWidth
                                Layout.preferredHeight: Core.UiStyle.controlHeightCompact

                                Text {
                                    anchors.centerIn: parent
                                    font.family: Core.Theme.fontFamily
                                    text: "󰍜"
                                    color: menuPopup.menuOpen ? Core.Theme.accent : Core.Theme.foreground
                                    font.pixelSize: Core.Theme.barIconSize
                                }
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

                            Repeater {
                                model: (Services.LayoutService.bar.regions.end || [])
                                    .filter(function(entry) { return entry.instance === "session-main" })
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
                }
            }
        }
    }
}
