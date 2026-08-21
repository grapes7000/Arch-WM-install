import QtQuick
import "../core" as Core

// Semantic interactive surface for compact bar controls. The active UI-style
// contract decides whether this behaves like a filled legacy pill or a quiet
// precision control; colors remain entirely theme-role driven.
Rectangle {
    id: root

    property bool active: false
    property bool scaleEnabled: true
    readonly property bool quiet: Core.UiStyle.quietButtons
    property real growScale: quiet ? 1.0 : 1.02
    property real pressScale: quiet ? 0.99 : 0.97
    property real stateScale: root.scaleEnabled
        ? (root.active ? pressScale : (hover.hovered ? growScale : 1.0))
        : 1.0
    property real pressPop: 1.0

    readonly property color idleColor: quiet
        ? Core.Theme.alphaColor(Core.Theme.surfaceRaised, 0.0)
        : Core.Theme.alphaColor(Core.Theme.surfaceRaised, 0.72)
    readonly property color hoverColor: quiet
        ? Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.42)
        : Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.94)
    readonly property color pressColor: Core.Theme.alphaColor(
        Core.Theme.selected,
        quiet ? 0.18 : 0.34
    )
    readonly property color idleBorder: quiet
        ? Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.0)
        : Core.Theme.alphaColor(
            Core.Theme.barOutlineColor,
            Math.max(0.24, Core.Theme.barOutlineOpacity * 0.72)
        )
    readonly property color hoverBorder: Core.Theme.alphaColor(
        Core.Theme.accent,
        quiet ? 0.34 : 0.62
    )
    readonly property color pressBorder: Core.Theme.alphaColor(
        Core.Theme.selected,
        quiet ? 0.62 : 0.90
    )

    radius: Core.UiStyle.radiusControl
    color: root.active ? pressColor
        : (hover.hovered ? (tap.pressed ? pressColor : hoverColor) : idleColor)
    opacity: tap.pressed ? (quiet ? 0.96 : 0.88) : 1.0
    border.width: Core.UiStyle.borderWidth
    border.color: root.active ? pressBorder
        : (hover.hovered ? (tap.pressed ? pressBorder : hoverBorder) : idleBorder)
    scale: root.stateScale * root.pressPop

    Behavior on stateScale {
        NumberAnimation {
            duration: quiet ? Core.Theme.animationMs : Core.Theme.animationMs * 2
            easing.type: Easing.OutCubic
        }
    }
    Behavior on opacity { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
    Behavior on color { ColorAnimation { duration: Core.Theme.animationMs } }
    Behavior on border.color { ColorAnimation { duration: Core.Theme.animationMs } }

    HoverHandler { id: hover; blocking: false }

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

    NumberAnimation {
        id: pressAnim
        target: root
        property: "pressPop"
        to: quiet ? 0.99 : 0.97
        duration: 60
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: bounceAnim
        target: root
        property: "pressPop"
        to: 1.0
        duration: quiet ? 90 : 140
        easing.type: quiet ? Easing.OutCubic : Easing.OutBack
        easing.overshoot: quiet ? 0.0 : 2.2
    }
}
