import QtQuick
import "../core" as Core

// Animated pill background used behind bar widgets and buttons. It observes
// hover and press passively (blocking: false) so the widget's own mouse areas
// keep receiving clicks, and animates a subtle grow on hover, a dip on press,
// and a gentle accent tint per state. `active` forces the pressed look for
// items whose popup is currently open.
Rectangle {
    id: root

    property bool active: false
    // Widgets that animate their own elements on hover (e.g. workspaces)
    // disable the container scale so the whole group doesn't move together.
    property bool scaleEnabled: true
    property real growScale: 1.02
    property real pressScale: 0.97

    // String -> color conversion is implicit on color-typed properties.
    readonly property color _accent: Core.Theme.accent
    readonly property color _accent2: Core.Theme.accent2

    // Idle state is deliberately visible: a filled pill with a soft outline so
    // the boxes read clearly on the bar even before any interaction.
    readonly property color idleColor: Qt.rgba(1, 1, 1, 0.10)
    readonly property color hoverColor: Qt.rgba(
        _accent.r * 0.16 + 0.12,
        _accent.g * 0.16 + 0.12,
        _accent.b * 0.16 + 0.12,
        0.20)
    readonly property color pressColor: Qt.rgba(
        _accent2.r * 0.20 + 0.12,
        _accent2.g * 0.20 + 0.12,
        _accent2.b * 0.20 + 0.12,
        0.26)
    readonly property color idleBorder: Qt.rgba(1, 1, 1, 0.28)
    readonly property color hoverBorder: Qt.rgba(_accent.r, _accent.g, _accent.b, 0.55)
    readonly property color pressBorder: Qt.rgba(_accent2.r, _accent2.g, _accent2.b, 0.85)

    radius: Math.max(6, Core.Theme.radius - 2)
    color: root.active ? pressColor
        : (hover.hovered ? (hover.pressed ? pressColor : hoverColor) : idleColor)
    border.width: Core.Theme.borderWidth
    border.color: root.active ? pressBorder
        : (hover.hovered ? (hover.pressed ? pressBorder : hoverBorder) : idleBorder)
    scale: root.scaleEnabled
        ? (root.active ? pressScale
            : (hover.hovered ? (hover.pressed ? pressScale : growScale) : 1.0))
        : 1.0

    Behavior on scale {
        NumberAnimation { duration: Core.Theme.animationMs * 2; easing.type: Easing.OutCubic }
    }
    Behavior on color {
        ColorAnimation { duration: Core.Theme.animationMs * 2 }
    }
    Behavior on border.color {
        ColorAnimation { duration: Core.Theme.animationMs * 2 }
    }

    HoverHandler {
        id: hover
        blocking: false
    }
}
