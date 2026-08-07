import QtQuick
import "../../core" as Core

Rectangle {
    id: root

    property bool active: false
    property bool interactive: false
    property alias hoverHandler: hover

    radius: Core.Theme.radius + 4
    color: {
        const token = active ? Core.Theme.surfaceElevated : Core.Theme.surfaceRaised
        const c = Qt.color(token)
        const alpha = active ? Math.min(1.0, Core.Theme.surfaceOpacity + 0.03) : Core.Theme.surfaceOpacity
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }
    border.width: active ? Math.max(2, Core.Theme.borderWidth) : Core.Theme.borderWidth
    border.color: active ? Core.Theme.accent : (Core.Theme.roles.border_subtle || Core.Theme.accent2)
    scale: interactive && hover.hovered ? 1.015 : 1.0

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
