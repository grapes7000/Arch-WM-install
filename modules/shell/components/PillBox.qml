import QtQuick
import "../core" as Core

// Semantic interactive surface for compact bar controls. Geometry, colors,
// and motion personality are resolved independently by the active contracts.
Rectangle {
    id: root

    property bool active: false
    property bool scaleEnabled: true
    readonly property bool quiet: Core.UiStyle.quietButtons
    property real growScale: Core.UiStyle.motionNone ? 1.0
        : (Core.UiStyle.motionRestrained ? 1.015 : 1.02)
    property real pressScale: Core.UiStyle.pressScale
    property real stateScale: root.scaleEnabled
        ? (tap.pressed ? pressScale : (hover.hovered ? growScale : 1.0))
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
    opacity: tap.pressed && !Core.UiStyle.motionNone ? (quiet ? 0.96 : 0.88) : 1.0
    border.width: Core.UiStyle.borderWidth
    border.color: root.active ? pressBorder
        : (hover.hovered ? (tap.pressed ? pressBorder : hoverBorder) : idleBorder)
    scale: root.stateScale * root.pressPop

    Behavior on stateScale {
        NumberAnimation {
            duration: Core.UiStyle.motionFastMs
            easing.type: Easing.OutCubic
        }
    }
    Behavior on opacity { NumberAnimation { duration: Core.UiStyle.motionFastMs; easing.type: Easing.OutQuad } }
    Behavior on color { ColorAnimation { duration: Core.UiStyle.motionFastMs } }
    Behavior on border.color { ColorAnimation { duration: Core.UiStyle.motionFastMs } }

    HoverHandler { id: hover; blocking: false }

    TapHandler {
        id: tap
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.WithinBounds
        onPressedChanged: {
            if (!root.scaleEnabled || Core.UiStyle.motionNone) {
                root.pressPop = 1.0
                return
            }
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
        to: Core.UiStyle.pressScale
        duration: Core.UiStyle.motionFastMs
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: bounceAnim
        target: root
        property: "pressPop"
        to: 1.0
        duration: Core.UiStyle.motionNormalMs
        easing.type: Core.UiStyle.motionPlayful ? Easing.OutBack : Easing.OutCubic
        easing.overshoot: Core.UiStyle.releaseOvershoot
    }
}
