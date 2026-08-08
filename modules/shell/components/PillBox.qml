import QtQuick
import "../core" as Core

// Animated pill background used behind bar widgets and buttons. Colors come
// entirely from the shared theme contract so Theme Studio changes are visible
// on the shell instead of being washed out by hard-coded white overlays.
Rectangle {
    id: root

    property bool active: false
    property bool scaleEnabled: true
    property real growScale: 1.02
    property real pressScale: 0.97
    property real stateScale: root.scaleEnabled
        ? (root.active ? pressScale : (hover.hovered ? growScale : 1.0))
        : 1.0
    property real pressPop: 1.0

    readonly property color idleColor: Core.Theme.alphaColor(Core.Theme.surfaceRaised, 0.72)
    readonly property color hoverColor: Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.94)
    readonly property color pressColor: Core.Theme.alphaColor(Core.Theme.selected, 0.34)
    readonly property color idleBorder: Core.Theme.alphaColor(
        Core.Theme.barOutlineColor,
        Math.max(0.24, Core.Theme.barOutlineOpacity * 0.72)
    )
    readonly property color hoverBorder: Core.Theme.alphaColor(Core.Theme.accent, 0.62)
    readonly property color pressBorder: Core.Theme.alphaColor(Core.Theme.selected, 0.90)

    radius: Math.max(6, Core.Theme.barRadius - 2)
    color: root.active ? pressColor
        : (hover.hovered ? (tap.pressed ? pressColor : hoverColor) : idleColor)
    opacity: tap.pressed ? 0.88 : 1.0
    border.width: Math.max(1, Core.Theme.barOutlineWidth)
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
        to: 0.97
        duration: 60
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: bounceAnim
        target: root
        property: "pressPop"
        to: 1.0
        duration: 140
        easing.type: Easing.OutBack
        easing.overshoot: 2.2
    }
}
