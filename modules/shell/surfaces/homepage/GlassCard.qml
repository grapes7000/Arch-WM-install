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
        return Qt.rgba(c.r, c.g, c.b, active ? 0.84 : 0.68)
    }
    border.width: active ? 2 : Core.Theme.borderWidth
    border.color: {
        if (active) return Core.Theme.accent
        var c = Qt.color(Core.Theme.accent2)
        return Qt.rgba(c.r, c.g, c.b, 0.34)
    }
    scale: interactive && hover.hovered ? 1.015 : 1.0

    Behavior on scale {
        NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
    }

    Behavior on border.color {
        ColorAnimation { duration: 190 }
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
