import QtQuick
import "../../core" as Core

Rectangle {
    id: root

    property bool active: false
    property bool interactive: false
    // Extra fill opacity above the theme's surface opacity. Content cards that
    // sit directly over the hero wallpaper use this so their panel box reads
    // as a solid background rather than a faint tint.
    property real fillAlphaBoost: 0
    property alias hoverHandler: hover
    // Multiplies the hover scale below; pops briefly above 1.0 on release
    // and eases back. Only driven when interactive (clickable cards).
    property real bounce: 1.0

    radius: Core.Theme.radius + 4
    color: {
        const token = active ? Core.Theme.surfaceElevated : Core.Theme.surfaceRaised
        const c = Qt.color(token)
        const alpha = Math.min(1.0, Core.Theme.surfaceOpacity + fillAlphaBoost
            + (active ? 0.16 : 0))
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }
    border.width: active ? Math.max(2, Core.Theme.borderWidth) : Core.Theme.borderWidth
    border.color: active ? Core.Theme.accent : (Core.Theme.roles.border_subtle || Core.Theme.accent2)
    scale: (interactive && hover.hovered ? 1.015 : 1.0) * root.bounce

    Behavior on scale {
        NumberAnimation {
            duration: Math.round(Core.Theme.animationMs * Core.Theme.motionScale)
            easing.type: Core.Theme.animationProfile === "snappy" ? Easing.OutQuad : Easing.OutCubic
        }
    }

    Behavior on border.color {
        ColorAnimation { duration: Math.round(Core.Theme.animationMs * Core.Theme.motionScale) }
    }

    HoverHandler {
        id: hover
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
    }

    // Non-exclusive tap tracking for the press/release bounce; does not grab
    // the event, so a TapHandler/MouseArea elsewhere on this card (e.g.
    // RailCard's own click handler) still fires normally.
    TapHandler {
        id: tap
        enabled: root.interactive
        gesturePolicy: TapHandler.WithinBounds
        onPressedChanged: {
            if (!pressed)
                bounceAnim.restart()
        }
    }

    SequentialAnimation {
        id: bounceAnim
        NumberAnimation { target: root; property: "bounce"; to: 1.06; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "bounce"; to: 1.0; duration: 130; easing.type: Easing.OutBack; easing.overshoot: 3 }
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
            NumberAnimation { duration: Math.round(Core.Theme.animationMs * Core.Theme.motionScale) }
        }
    }
}
