import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../core" as Core
import "../../services" as Services

Scope {
    id: root

    readonly property var drawerSources: ({
        calendar: Qt.resolvedUrl("../../widgets/clock/Panel.qml"),
        audio: Qt.resolvedUrl("../../widgets/volume/Panel.qml"),
        bluetooth: Qt.resolvedUrl("../../widgets/bluetooth/Panel.qml"),
        network: Qt.resolvedUrl("../../widgets/network/Panel.qml"),
        system: Qt.resolvedUrl("../../widgets/system-stats/Panel.qml"),
        notifications: Qt.resolvedUrl("../../widgets/notifications/Panel.qml"),
        session: Qt.resolvedUrl("../../widgets/session/Panel.qml"),
        weather: Qt.resolvedUrl("../../widgets/weather/Panel.qml"),
        battery: Qt.resolvedUrl("../../widgets/battery/Panel.qml")
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
        property real revealProgress: 1.0

        function startReveal() {
            revealAnimation.stop()
            if (Core.Theme.motionScale <= 0.05 || Core.UiStyle.motionNone) {
                revealProgress = 1.0
                return
            }
            revealProgress = 0.0
            revealAnimation.restart()
        }

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

        onVisibleChanged: {
            if (visible)
                Qt.callLater(drawerWindow.startReveal)
            else {
                revealAnimation.stop()
                revealProgress = (Core.Theme.motionScale <= 0.05 || Core.UiStyle.motionNone) ? 1.0 : 0.0
            }
        }

        NumberAnimation {
            id: revealAnimation
            target: drawerWindow
            property: "revealProgress"
            from: 0.0
            to: 1.0
            duration: Math.round(Core.UiStyle.motionNormalMs * Core.Theme.motionScale)
            easing.type: Core.UiStyle.motionPlayful ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: Core.UiStyle.motionPlayful ? 1.18 : 0.0
        }

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
                    const edge = Math.max(Core.Theme.drawerOffset, Core.Theme.barOuterMargin)
                    if (!controller.anchorItem)
                        return drawerWindow.width - width - edge
                    const point = controller.anchorItem.mapToItem(
                        null,
                        controller.anchorItem.width / 2,
                        controller.anchorItem.height
                    )
                    return Math.max(
                        edge,
                        Math.min(drawerWindow.width - width - edge, point.x - width / 2)
                    )
                }

                readonly property real availableHeight: Math.max(
                    120,
                    drawerWindow.height
                        - Core.Theme.barHeight
                        - Core.Theme.barOuterMargin * 2
                        - Core.Theme.drawerOffset * 2
                )

                x: anchoredX()
                y: Core.Theme.barPosition === "top"
                    ? Core.Theme.barHeight + Core.Theme.barOuterMargin * 2 + Core.Theme.drawerOffset
                    : drawerWindow.height - height - Core.Theme.barHeight
                        - Core.Theme.barOuterMargin * 2 - Core.Theme.drawerOffset
                width: Math.min(
                    drawerWindow.width - Math.max(Core.UiStyle.spacingSm, Core.Theme.drawerOffset) * 2,
                    Core.Theme.drawerWidth
                )
                height: Math.min(
                    contentLoader.implicitHeight + Core.Theme.drawerPadding * 2,
                    availableHeight
                )
                radius: Core.Theme.drawerRadius
                color: Core.Theme.alphaColor(Core.Theme.drawerSurfaceColor, Core.Theme.drawerOpacity)
                border.width: Core.Theme.drawerOutlineWidth
                border.color: Core.Theme.alphaColor(
                    Core.Theme.drawerOutlineColor,
                    Core.Theme.drawerOutlineOpacity
                )
                opacity: Math.max(0.0, Math.min(1.0, drawerWindow.revealProgress))
                scale: Core.UiStyle.motionPlayful ? (0.96 + drawerWindow.revealProgress * 0.04) : 1.0
                transform: Translate {
                    x: Core.UiStyle.motionNone ? 0
                        : (1.0 - drawerWindow.revealProgress)
                            * (Core.UiStyle.motionRestrained ? Core.UiStyle.spacingSm : 26)
                    y: Core.UiStyle.motionNone ? 0
                        : (1.0 - drawerWindow.revealProgress)
                            * (Core.Theme.barPosition === "top" ? -Core.UiStyle.grid : Core.UiStyle.grid)
                }
                MouseArea { anchors.fill: parent }

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    anchors.margins: Core.Theme.drawerPadding
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
