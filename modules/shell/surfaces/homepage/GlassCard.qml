import QtQuick
import "../../core" as Core

Rectangle {
    id: root

    property bool active: false
    property bool interactive: false
    // Extra fill opacity above the theme's configured homepage-card opacity.
    // Content cards that sit directly over the hero wallpaper use this so
    // their panel box reads as a solid background rather than a faint tint.
    property real fillAlphaBoost: 0
    property alias hoverHandler: hover
    // Multiplies the hover scale below; dips on press and settles back to
    // exactly 1.0 (the card's regular size) on release. Only driven when
    // interactive (clickable cards).
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

    // The card's one and only tap handler: a second TapHandler/MouseArea
    // layered on top of this can grab-conflict with this one in Qt6 and
    // silently stop the bounce (or the click) from firing. Subclasses should
    // use clicked() instead of adding their own handler.
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
        color: interactive && hover.hovered ? Core.Theme.surfaceHover : "transparent"
        opacity: interactive && hover.hovered ? 0.22 : 0
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, hover.hovered ? 0.12 : 0.06)
        Behavior on opacity {
            NumberAnimation { duration: Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale) }
        }
    }
}
