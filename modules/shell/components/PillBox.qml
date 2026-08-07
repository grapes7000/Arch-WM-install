import QtQuick
import "../core" as Core

// Animated pill background used behind bar widgets and buttons. It observes
// hover and press passively (blocking: false / non-exclusive tap) so the
// widget's own mouse areas keep receiving clicks, and animates a subtle grow
// on hover, a dip+dim on press, a snappy overshoot bounce back on release,
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
    // Multiplies the state-driven scale above; pops briefly above 1.0 on
    // release and eases back, independent of the hover/press target scale.
    property real bounce: 1.0

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
        : (hover.hovered ? (tap.pressed ? pressColor : hoverColor) : idleColor)
    opacity: tap.pressed ? 0.85 : 1.0
    border.width: Core.Theme.borderWidth
    border.color: root.active ? pressBorder
        : (hover.hovered ? (tap.pressed ? pressBorder : hoverBorder) : idleBorder)
    scale: (root.scaleEnabled
        ? (root.active ? pressScale
            : (hover.hovered ? (tap.pressed ? pressScale : growScale) : 1.0))
        : 1.0) * root.bounce

    Behavior on scale {
        NumberAnimation { duration: Core.Theme.animationMs * 2; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: Core.Theme.animationMs; easing.type: Easing.OutQuad }
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

    // Non-exclusive tap tracking: reports press state without grabbing the
    // event, so the widget's own MouseArea underneath still gets the click.
    TapHandler {
        id: tap
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.WithinBounds
        onPressedChanged: {
            if (!pressed && root.scaleEnabled)
                bounceAnim.restart()
        }
    }

    SequentialAnimation {
        id: bounceAnim
        NumberAnimation { target: root; property: "bounce"; to: 1.06; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "bounce"; to: 1.0; duration: 130; easing.type: Easing.OutBack; easing.overshoot: 3 }
    }
}
