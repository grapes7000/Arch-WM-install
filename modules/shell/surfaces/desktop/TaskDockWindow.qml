import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components

PanelWindow {
    id: root

    required property var modelData
    property bool shown: false
    property string selectedGroupKey: ""
    property int hoveredGroupIndex: -1
    readonly property var selectedGroup: {
        for (const group of dockModel.groups) {
            if (group.key === selectedGroupKey)
                return group
        }
        return null
    }

    screen: modelData
    anchors {
        left: true
        right: true
        bottom: true
    }
    implicitHeight: Core.Theme.barHeight * 4
    color: "transparent"
    aboveWindows: true
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    visible: !Services.LockStateService.locked
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "arch-wm-task-dock"
    mask: Region {
        Region { item: root.shown ? revealedHitZone : triggerZone }
    }

    function open() {
        hideTimer.stop()
        shown = true
        return true
    }

    function close() {
        hideTimer.stop()
        shown = false
        selectedGroupKey = ""
        hoveredGroupIndex = -1
        return true
    }

    function toggle() {
        return shown ? close() : open()
    }

    function scheduleHide() {
        if (!dockHover.hovered)
            hideTimer.restart()
    }

    function focusWindow(window) {
        if (!window)
            return
        if (window.wayland && typeof window.wayland.activate === "function") {
            window.wayland.activate()
        } else if (window.address) {
            Hyprland.dispatch("focuswindow address:" + String(window.address))
        }
        close()
    }

    function chooseGroup(group) {
        if (!group)
            return
        if (group.windows.length === 0) {
            const entry = group.desktopId ? DesktopEntries.byId(group.desktopId) : null
            if (!entry)
                return
            Services.LauncherStateService.recordLaunch(group.desktopId)
            entry.execute()
            close()
            return
        }
        if (group.windows.length === 1) {
            focusWindow(group.windows[0])
            return
        }
        selectedGroupKey = selectedGroupKey === group.key ? "" : group.key
    }

    DockModel {
        id: dockModel
        monitorName: root.modelData ? root.modelData.name : ""
        sourceToplevels: Hyprland.toplevels
        desktopEntries: DesktopEntries.applications
        favoriteIds: Services.LauncherStateService.favorites
    }

    Item {
        id: interactionZone
        width: Math.min(root.width * 0.8, Core.Theme.barHeight * 18)
        height: root.height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        HoverHandler {
            id: dockHover
            onHoveredChanged: {
                if (hovered)
                    root.open()
                else
                    root.scheduleHide()
            }
        }

        Rectangle {
            id: chooser
            visible: root.shown && root.selectedGroup !== null
            width: Math.min(interactionZone.width, Core.Theme.barHeight * 7)
            height: visible
                ? Math.min(Core.Theme.barHeight * 4,
                           Core.Theme.barHeight + root.selectedGroup.windows.length
                           * (Core.Theme.barHeight - Core.Theme.gap))
                : 0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: dockFrame.top
            anchors.bottomMargin: Core.Theme.gap
            color: Core.Theme.surface
            radius: Core.Theme.radius
            border.width: Core.Theme.borderWidth
            border.color: Core.Theme.accent2
            clip: true

            ListView {
                anchors.fill: parent
                anchors.margins: Core.Theme.gap
                spacing: Math.max(1, Core.Theme.gap / 2)
                clip: true
                model: root.selectedGroup ? root.selectedGroup.windows : []

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: Core.Theme.barHeight - Core.Theme.gap
                    radius: Core.Theme.radius
                    color: chooserMouse.containsMouse || modelData.activated
                        ? Core.Theme.accent : Core.Theme.background
                    border.width: Core.Theme.borderWidth
                    border.color: modelData.urgent
                        ? Core.Theme.urgent : Core.Theme.accent2

                    Text {
                        anchors.left: parent.left
                        anchors.right: workspaceLabel.left
                        anchors.leftMargin: Core.Theme.gap
                        anchors.rightMargin: Core.Theme.gap
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.title || "Untitled window"
                        color: modelData.activated
                            ? Core.Theme.background : Core.Theme.foreground
                        elide: Text.ElideRight
                    }

                    Text {
                        id: workspaceLabel
                        anchors.right: parent.right
                        anchors.rightMargin: Core.Theme.gap
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.workspace
                            ? "WS " + modelData.workspace.name : ""
                        color: Core.Theme.muted
                    }

                    MouseArea {
                        id: chooserMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.focusWindow(modelData)
                    }
                    Components.PressBounce { pressed: chooserMouse.pressed }
                }
            }
        }

        Rectangle {
            id: dockFrame
            width: Math.min(interactionZone.width,
                            Math.max(Core.Theme.barHeight * 2,
                                     dockRow.implicitWidth + Core.Theme.gap * 2))
            height: Core.Theme.barHeight + Core.Theme.gap * 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Core.Theme.gap
            color: Core.Theme.alphaColor(Core.Theme.surface, 0.58)
            radius: Math.min(height / 2, Core.Theme.radius * 2.25)
            border.width: 0
            opacity: root.shown ? 1 : 0
            transform: Translate {
                y: root.shown ? 0 : Core.Theme.gap * 2
                Behavior on y {
                    NumberAnimation {
                        duration: Core.Theme.animationMs
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Core.Theme.animationMs
                    easing.type: Easing.OutCubic
                }
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: Core.InteractiveShellController.launcher("open")
            }

            Row {
                id: dockRow
                anchors.centerIn: parent
                spacing: 0

                HoverHandler {
                    onHoveredChanged: {
                        if (!hovered)
                            root.hoveredGroupIndex = -1
                    }
                }

                Repeater {
                    model: dockModel.groups

                    Item {
                        id: groupButton
                        required property var modelData
                        required property int index
                        readonly property real lift: root.hoveredGroupIndex < 0
                            ? 0 : Math.max(0, 18 - Math.abs(index - root.hoveredGroupIndex) * 8)
                        width: Core.Theme.barHeight + Core.Theme.gap
                        height: Core.Theme.barHeight

                        Item {
                            id: iconVisual
                            width: Core.Theme.barHeight
                            height: Core.Theme.barHeight
                            anchors.centerIn: parent
                            transform: Translate {
                                y: -groupButton.lift
                                Behavior on y {
                                    NumberAnimation {
                                        duration: Math.max(120, Core.Theme.animationMs)
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            IconImage {
                                anchors.centerIn: parent
                                width: parent.width
                                height: width
                                source: Quickshell.iconPath(modelData.icon, true)
                            }
                        }

                        Rectangle {
                            width: modelData.active ? 16 : 9
                            height: 5
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: -Math.max(3, Core.Theme.gap / 2)
                            radius: height / 2
                            color: modelData.urgent ? Core.Theme.urgent
                                : (modelData.active ? Core.Theme.accent : Core.Theme.foreground)
                            opacity: modelData.running ? 1 : 0
                            z: 2

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Math.max(100, Core.Theme.animationMs)
                                }
                            }
                            Behavior on width {
                                NumberAnimation {
                                    duration: Math.max(100, Core.Theme.animationMs)
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MouseArea {
                            id: groupMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton
                            onEntered: root.hoveredGroupIndex = index
                            onClicked: root.chooseGroup(modelData)
                        }
                        Components.PressBounce {
                            target: iconVisual
                            pressed: groupMouse.pressed
                        }
                    }
                }
            }
        }

        Item {
            id: revealedHitZone
            width: Math.max(dockFrame.width, chooser.width)
            height: root.height
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
        }

        Item {
            id: triggerZone
            width: Math.min(interactionZone.width, Core.Theme.barHeight * 4)
            height: Math.max(Core.Theme.borderWidth * 2, Core.Theme.gap / 2)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
        }
    }

    Timer {
        id: hideTimer
        interval: Math.max(250, Core.Theme.animationMs * 3)
        onTriggered: root.close()
    }

    onVisibleChanged: {
        if (!visible)
            close()
    }
}
