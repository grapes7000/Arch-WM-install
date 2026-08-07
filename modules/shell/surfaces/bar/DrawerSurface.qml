import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../core" as Core
import "../../services" as Services

Scope {
    id: root

    readonly property var drawerSources: ({
        calendar: Qt.resolvedUrl("CalendarDrawer.qml"),
        audio: Qt.resolvedUrl("AudioDrawer.qml"),
        network: Qt.resolvedUrl("NetworkDrawer.qml"),
        system: Qt.resolvedUrl("SystemDrawer.qml"),
        notifications: Qt.resolvedUrl("NotificationsDrawer.qml"),
        session: Qt.resolvedUrl("SessionDrawer.qml"),
        weather: Qt.resolvedUrl("WeatherDrawer.qml")
    })

    DrawerController {
        id: controller
        locked: Services.LockStateService.locked
    }

    Binding {
        target: Core.InteractiveShellController
        property: "drawerController"
        value: controller
        restoreMode: Binding.RestoreBindingOrValue
    }

    PanelWindow {
        id: drawerWindow

        screen: controller.screen
        visible: controller.visible && !controller.locked
        anchors { top: true; right: true; bottom: true; left: true }
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: controller.activeKind
            ? "arch-wm-drawer-" + controller.activeKind : "arch-wm-drawer"

        Item {
            id: dismissal
            anchors.fill: parent
            focus: drawerWindow.visible
            Keys.onEscapePressed: controller.close()

            MouseArea {
                anchors.fill: parent
                onClicked: controller.close()
            }

            Rectangle {
                id: card

                function anchoredX() {
                    if (!controller.anchorItem)
                        return drawerWindow.width - width - Core.Theme.gap * 2
                    const point = controller.anchorItem.mapToItem(
                        null,
                        controller.anchorItem.width / 2,
                        controller.anchorItem.height
                    )
                    return Math.max(
                        Core.Theme.gap,
                        Math.min(drawerWindow.width - width - Core.Theme.gap, point.x - width / 2)
                    )
                }

                x: anchoredX()
                y: Core.Theme.barHeight + Core.Theme.gap * 3
                width: Math.min(drawerWindow.width - Core.Theme.gap * 2, 420)
                height: Math.min(
                    contentLoader.implicitHeight + Core.Theme.gap * 4,
                    drawerWindow.height - y - Core.Theme.gap * 2
                )
                radius: Core.Theme.radius
                color: Core.Theme.surface
                border.width: Core.Theme.borderWidth
                border.color: Core.Theme.accent2
                MouseArea { anchors.fill: parent }

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    anchors.margins: Core.Theme.gap * 2
                    source: root.drawerSources[controller.activeKind] || ""
                    onLoaded: {
                        if (item && item.hasOwnProperty("closeDrawer"))
                            item.closeDrawer = controller.close
                    }
                }
            }
        }
    }
}
