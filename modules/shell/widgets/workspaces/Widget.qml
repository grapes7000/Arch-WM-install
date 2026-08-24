import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../core" as Core

Item {
    id: root

    property var context: ({
        variant: "standard",
        settings: ({}),
        locked: false,
        allows: function() { return false }
    })

    // Each indicator animates independently. The surrounding PillBox stays
    // still so hover/select motion cannot double-scale the workspace strip.
    Component.onCompleted: {
        if (parent && parent.hasOwnProperty("scaleEnabled"))
            parent.scaleEnabled = false
    }

    readonly property var slots: [
        { name: "web", icon: "󰈹" },
        { name: "term", icon: "󰆍" },
        { name: "dev", icon: "󰨞" },
        { name: "media", icon: "󰓇" },
        { name: "files", icon: "󰉋" },
        { name: "settings", icon: "󰒓" },
        { name: "chat", icon: "󰙯" },
        { name: "mail", icon: "󰒊" },
        { name: "media", icon: "󰘽" },
        { name: "sys", icon: "󰖲" }
    ]

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    readonly property bool showAllLabels: context && context.settings
        && context.settings.showLabels === true
        && root.width >= 1050

    function workspaceFor(id) {
        const workspaces = Hyprland.workspaces.values
        for (let i = 0; i < workspaces.length; ++i) {
            const workspace = workspaces[i]
            if (workspace && workspace.id === id) return workspace
        }
        return null
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: context.variant === "compact" ? Core.UiStyle.spacingXs : Core.UiStyle.spacingSm

        Repeater {
            model: root.slots

            Rectangle {
                id: box
                required property var modelData
                required property int index
                readonly property int workspaceId: index + 1
                readonly property var ws: root.workspaceFor(workspaceId)
                readonly property bool selected: !!ws && ws.focused
                readonly property bool active: !!ws && ws.active

                // Bar workspaces must remain inside the actual layer-surface
                // height. Precision and Win95 reserve extra headroom; Legacy's
                // taller bar has room for the playful grow/lift animation.
                readonly property int compactBase: Math.max(
                    18,
                    Math.min(
                        Core.UiStyle.controlHeightCompact,
                        Core.Theme.barHeight - Core.Theme.barPadding * 2
                            - (Core.UiStyle.motionPlayful ? 2 : Core.UiStyle.spacingXs)
                    )
                )
                readonly property int base: context.variant === "compact"
                    ? compactBase : Math.max(36, Core.UiStyle.controlHeightLarge)
                readonly property int selectedGrowth: Core.UiStyle.motionPlayful ? 4 : 0

                property bool hovered: false
                property real hoverScale: 1.0
                property real liftY: 0
                property real pulse: 1.0

                Behavior on hoverScale {
                    NumberAnimation { duration: Core.UiStyle.motionFastMs; easing.type: Easing.OutCubic }
                }
                Behavior on liftY {
                    NumberAnimation { duration: Core.UiStyle.motionFastMs; easing.type: Easing.OutCubic }
                }
                onHoveredChanged: {
                    hoverScale = hovered ? Core.UiStyle.hoverScale : 1.0
                    liftY = hovered ? Core.UiStyle.hoverLift : 0
                }

                readonly property color activeTint: {
                    const c = Qt.color(Core.Theme.accent2)
                    return Qt.rgba(c.r, c.g, c.b, Core.UiStyle.flatSurfaces ? 0.18 : 0.28)
                }

                Layout.preferredWidth: (selected || root.showAllLabels)
                    ? content.implicitWidth + base * 0.8 : base
                Layout.preferredHeight: base + (selected ? selectedGrowth : 0)
                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: Core.UiStyle.motionNormalMs; easing.type: Easing.OutCubic }
                }
                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: Core.UiStyle.motionNormalMs; easing.type: Easing.OutCubic }
                }

                radius: Core.UiStyle.radiusControl
                color: selected ? Core.Theme.accent
                    : active ? activeTint
                    : hovered ? Core.Theme.surfaceHover
                    : "transparent"
                Behavior on color { ColorAnimation { duration: Core.UiStyle.motionFastMs } }

                border.width: selected ? 0 : Core.UiStyle.borderWidth
                border.color: selected ? Core.Theme.accent
                    : active ? Core.Theme.accent2
                    : hovered ? Core.Theme.accent2
                    : Core.Theme.roles.border_normal
                Behavior on border.color {
                    ColorAnimation { duration: Core.UiStyle.motionFastMs }
                }

                scale: hoverScale * pulse
                transform: Translate { y: box.liftY }

                RowLayout {
                    id: content
                    anchors.centerIn: parent
                    spacing: Core.UiStyle.spacingXs

                    Text {
                        text: modelData.icon
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: context.variant === "compact"
                            ? Math.max(Core.UiStyle.iconSize, box.selected ? Core.UiStyle.iconSize + 2 : Core.UiStyle.iconSize)
                            : Math.max(22, Core.UiStyle.iconSize + 8)
                        color: box.selected ? Core.Theme.background
                            : box.active ? Core.Theme.accent2
                            : Core.Theme.foreground
                        Behavior on color { ColorAnimation { duration: Core.UiStyle.motionFastMs } }
                    }

                    Text {
                        text: modelData.name
                        visible: box.selected || root.showAllLabels
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: root.showAllLabels ? Core.UiStyle.fontBody : Core.UiStyle.fontSecondary
                        font.bold: true
                        color: box.selected ? Core.Theme.background : Core.Theme.foreground
                        Behavior on color { ColorAnimation { duration: Core.UiStyle.motionFastMs } }
                    }
                }

                MouseArea {
                    id: workspaceMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: context.allows("workspace.switch")
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onEntered: box.hovered = true
                    onExited: box.hovered = false
                    onClicked: {
                        if (ws) {
                            ws.activate()
                        } else if (Hyprland.usingLua) {
                            Hyprland.dispatch('hl.dsp.focus({ workspace = ' + workspaceId + ' })')
                        } else {
                            Hyprland.dispatch("workspace " + workspaceId)
                        }
                    }
                }

                onSelectedChanged: {
                    if (!selected || Core.UiStyle.motionNone) {
                        pulseAnim.stop()
                        pulse = 1.0
                    } else {
                        pulseAnim.restart()
                    }
                }

                SequentialAnimation on pulse {
                    id: pulseAnim
                    running: false
                    NumberAnimation {
                        to: Core.UiStyle.selectedPulse
                        duration: Core.UiStyle.motionFastMs
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        to: 1.0
                        duration: Core.UiStyle.motionPlayful ? 260 : Core.UiStyle.motionNormalMs
                        easing.type: Core.UiStyle.motionPlayful ? Easing.OutBack : Easing.OutCubic
                        easing.overshoot: Core.UiStyle.releaseOvershoot
                    }
                }
            }
        }
    }
}
