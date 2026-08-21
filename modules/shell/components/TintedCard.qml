import QtQuick
import "../core" as Core

Rectangle {
    id: root

    property bool active: false
    property color tintColor: Core.Theme.accent
    property real activeFillAlpha: Core.UiStyle.flatSurfaces ? 0.045 : 0.06
    property real activeBorderAlpha: Core.UiStyle.flatSurfaces ? 0.22 : 0.3
    property real baseFillAlpha: Core.UiStyle.flatSurfaces ? 0.0 : 0.04
    property real baseBorderAlpha: Core.UiStyle.flatSurfaces ? 0.08 : 0.06

    readonly property color __fg: Qt.color(Core.Theme.foreground)

    radius: Core.UiStyle.radiusSurface
    color: active
        ? Qt.rgba(tintColor.r, tintColor.g, tintColor.b, activeFillAlpha)
        : Qt.rgba(__fg.r, __fg.g, __fg.b, baseFillAlpha)
    border.width: Core.UiStyle.borderWidth
    border.color: active
        ? Qt.rgba(tintColor.r, tintColor.g, tintColor.b, activeBorderAlpha)
        : Qt.rgba(__fg.r, __fg.g, __fg.b, baseBorderAlpha)
}
