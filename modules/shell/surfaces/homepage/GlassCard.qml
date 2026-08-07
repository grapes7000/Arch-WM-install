import QtQuick
import "../../core" as Core

Rectangle {
    id: root

    property bool active: false
    property bool interactive: false
    property alias hoverHandler: hover

    radius: Core.Theme.radius + 4
    color: {
        var c = Qt.color(Core.Theme.surface)
        var alpha = active ? Math.min(1.0, Core.Theme.surfaceOpacity + 0.16) : Core.Theme.surfaceOpacity
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }
    border.width: active ? 2 : Core.Theme.borderWidth
    border.color: {
        if (active) return Core.Theme.accent
        var c = Qt.color(Core.Theme.accent2)
        return Qt.rgba(c.r, c.g, c.b, 0.34)
    }
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
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, hover.hovered ? 0.16 : 0.08)
    }
}
