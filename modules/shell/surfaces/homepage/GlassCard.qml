import QtQuick
import "../../core" as Core

Rectangle {
    id: root

    property bool active: false
    property bool interactive: false
    property real fillAlphaBoost: 0
    property alias hoverHandler: hover
    property real bounce: 1.0
    signal clicked()

    radius: Core.Theme.homepageCardRadius
    color: {
        const token = active ? Core.Theme.surfaceElevated : Core.Theme.surfaceRaised
        const c = Qt.color(token)
        const alpha = Math.min(1.0, Core.Theme.homepageCardOpacity + fillAlphaBoost
            + (active ? 0.16 : 0))
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }
    border.width: active ? Math.max(2, Core.Theme.borderWidth) : Core.Theme.borderWidth
    border.color: active
        ? Core.Theme.accent
        : (Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor)
    scale: (interactive && hover.hovered ? 1.015 : 1.0) * root.bounce

    Behavior on scale {
        NumberAnimation {
            duration: Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale)
            easing.type: Core.Theme.animationProfile === "snappy" ? Easing.OutQuad : Easing.OutCubic
        }
    }

    Behavior on border.color {
        ColorAnimation { duration: Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale) }
    }

    HoverHandler {
        id: hover
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        enabled: root.interactive
        gesturePolicy: TapHandler.WithinBounds
        onTapped: root.clicked()
        onPressedChanged: {
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
        property: "bounce"
        to: 0.97
        duration: 60
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: bounceAnim
        target: root
        property: "bounce"
        to: 1.0
        duration: 140
        easing.type: Easing.OutBack
        easing.overshoot: 2.2
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, parent.radius - 1)
        color: interactive && hover.hovered
            ? Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.24)
            : "transparent"
        opacity: interactive && hover.hovered ? 1 : 0
        border.width: 1
        border.color: Core.Theme.alphaColor(
            Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor,
            hover.hovered ? 0.42 : 0.22
        )
        Behavior on opacity {
            NumberAnimation { duration: Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale) }
        }
    }
}
