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
    // Slow, eased target for hover/active state changes.
    readonly property real stateScale: root.scaleEnabled
        ? (root.active ? pressScale : (hover.hovered ? growScale : 1.0))
        : 1.0
    // Fast, un-eased press/release pop, driven directly off the tap so it
    // tracks the actual mouse-down/mouse-up timing instead of riding the
    // slower hover Behavior below. Multiplies into the final scale.
    property real pressPop: 1.0

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
    scale: root.stateScale * root.pressPop

    Behavior on stateScale {
        NumberAnimation { duration: Core.Theme.animationMs * 2; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
    }
    Behavior on color {
        ColorAnimation { duration: 120 }
    }
    Behavior on border.color {
        ColorAnimation { duration: 120 }
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
            if (!root.scaleEnabled)
                return
            if (pressed) {
                bounceAnim.stop()
                pressAnim.restart()
            } else {
                pressAnim.stop()
                bounceAnim.restart()
            }
        }
    }

    // Snappy, direct animations tracking real mouse-down/mouse-up timing —
    // no Behavior easing in between, so press feels immediate and the
    // rebound fires right as the button releases.
    NumberAnimation {
        id: pressAnim
        target: root
        property: "pressPop"
        to: 0.97
        duration: 60
        easing.type: Easing.OutQuad
    }

    SequentialAnimation {
        id: bounceAnim
        NumberAnimation { target: root; property: "pressPop"; to: 1.05; duration: 70; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "pressPop"; to: 1.0; duration: 110; easing.type: Easing.OutBack; easing.overshoot: 3 }
    }
}
