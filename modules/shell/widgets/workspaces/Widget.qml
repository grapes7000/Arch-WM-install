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

    // Semantic workspace slots, left to right. Each workspace id maps to a
    // purpose: an icon (Nerd Font glyph) and a lowercase label that is only
    // shown while the workspace is focused.
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

    // Look up a live Hyprland workspace by id. Reads `.values` rather than
    // indexing the model directly so QML re-evaluates this binding whenever
    // the workspace list changes (workspaces are created and destroyed as
    // windows open and close).
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
        spacing: context.variant === "compact" ? 4 : 7

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
                readonly property int base: context.variant === "compact" ? 30 : 38

                property bool hovered: false
                property real hoverScale: 1.0
                property real pulse: 1.0

                readonly property color activeTint: {
                    const c = Qt.color(Core.Theme.accent2)
                    return Qt.rgba(c.r, c.g, c.b, 0.28)
                }

                // Square box; the focused slot grows to show icon + label.
                Layout.preferredWidth: selected ? content.implicitWidth + base * 0.8 : base
                Layout.preferredHeight: selected ? base + 8 : base
                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: Core.Theme.animationMs * 2; easing.type: Easing.OutCubic }
                }
                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: Core.Theme.animationMs * 2; easing.type: Easing.OutCubic }
                }

                radius: 4
                color: selected ? Core.Theme.accent
                    : active ? activeTint
                    : hovered ? Core.Theme.surface
                    : "transparent"
                Behavior on color { ColorAnimation { duration: Core.Theme.animationMs; easing.type: Easing.OutCubic } }

<<<<<<< Updated upstream
                border.width: selected ? 0 : Core.Theme.borderWidth
                border.color: selected ? Core.Theme.accent
                    : active ? Core.Theme.accent2
                    : hovered ? Core.Theme.accent2
                    : Core.Theme.roles.border_normal
                Behavior on border.color {
                    ColorAnimation { duration: Core.Theme.animationMs; easing.type: Easing.OutCubic }
                }

                scale: hoverScale * pulse

                RowLayout {
                    id: content
=======
                Text {
                    font.family: Core.Theme.fontFamily
>>>>>>> Stashed changes
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: modelData.icon
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: box.selected ? 17 : (context.variant === "compact" ? 15 : 18)
                        color: box.selected ? Core.Theme.background
                            : box.active ? Core.Theme.accent2
                            : Core.Theme.foreground
                        Behavior on color { ColorAnimation { duration: Core.Theme.animationMs } }
                    }

                    Text {
                        text: modelData.name
                        visible: box.selected
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        color: Core.Theme.background
                        Behavior on color { ColorAnimation { duration: Core.Theme.animationMs } }
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
                            // Lua configs evaluate dispatchers as lua expressions.
                            Hyprland.dispatch('hl.dsp.focus({ workspace = ' + workspaceId + ' })')
                        } else {
                            Hyprland.dispatch("workspace " + workspaceId)
                        }
                    }
                }

                // Pop animation when a workspace becomes focused.
                onSelectedChanged: {
                    if (selected) pulseAnim.restart()
                }

                SequentialAnimation on pulse {
                    id: pulseAnim
                    running: false
                    NumberAnimation { to: 1.18; duration: 140; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 1.0; duration: 340; easing.type: Easing.OutBack }
                }
            }
        }
    }
}

