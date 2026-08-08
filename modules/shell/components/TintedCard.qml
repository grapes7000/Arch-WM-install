import QtQuick
import "../core" as Core

Rectangle {
    id: root

    property bool active: false
    property color tintColor: Core.Theme.accent
    property real activeFillAlpha: 0.06
    property real activeBorderAlpha: 0.3
    property real baseFillAlpha: 0.04
    property real baseBorderAlpha: 0.06

    readonly property color __fg: Qt.color(Core.Theme.foreground)

    radius: Math.max(6, Core.Theme.radius - 2)
    color: active
        ? Qt.rgba(tintColor.r, tintColor.g, tintColor.b, activeFillAlpha)
        : Qt.rgba(__fg.r, __fg.g, __fg.b, baseFillAlpha)
    border.width: 1
    border.color: active
        ? Qt.rgba(tintColor.r, tintColor.g, tintColor.b, activeBorderAlpha)
        : Qt.rgba(__fg.r, __fg.g, __fg.b, baseBorderAlpha)
}
