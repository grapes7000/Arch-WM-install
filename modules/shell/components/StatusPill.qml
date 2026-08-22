import QtQuick
import "../core" as Core

Rectangle {
    id: root

    property bool active: false
    property string activeLabel: "ON"
    property string inactiveLabel: "OFF"
    property color activeColor: Core.Theme.accent
    property bool pulse: Core.UiStyle.motionPlayful

    property bool pulseState: false
    readonly property bool mutedStatus: Core.UiStyle.patterns.status === "semantic-muted"
    readonly property color __fg: Qt.color(Core.Theme.foreground)

    width: label.implicitWidth + Core.UiStyle.spacingSm * 2
    height: Math.max(Core.UiStyle.controlHeightCompact, label.implicitHeight + Core.UiStyle.spacingXs)
    radius: mutedStatus ? Core.UiStyle.radiusControl : (Core.UiStyle.radiusControl === 0 ? 0 : height / 2)
    color: active
        ? (mutedStatus ? Core.Theme.alphaColor(activeColor, 0.14) : activeColor)
        : Qt.rgba(__fg.r, __fg.g, __fg.b, mutedStatus ? 0.0 : 0.06)
    border.width: Core.UiStyle.borderWidth
    border.color: active
        ? Core.Theme.alphaColor(activeColor, mutedStatus ? 0.45 : 0.0)
        : Core.Theme.alphaColor(Core.Theme.muted, mutedStatus ? 0.22 : 0.0)
    opacity: (active && pulse && !Core.UiStyle.motionNone) ? (pulseState ? 1.0 : 0.6) : 1.0

    Behavior on opacity {
        NumberAnimation { duration: Core.UiStyle.motionPlayful ? 750 : Core.UiStyle.motionFastMs; easing.type: Easing.InOutQuad }
    }

    Timer {
        running: root.active && root.pulse && Core.UiStyle.motionPlayful
        interval: 1500
        repeat: true
        onTriggered: root.pulseState = !root.pulseState
    }

    Text {
        id: label
        font.family: Core.Theme.fontFamily
        anchors.centerIn: parent
        text: root.active ? root.activeLabel : root.inactiveLabel
        color: root.active
            ? (root.mutedStatus ? root.activeColor : Core.Theme.background)
            : Core.Theme.muted
        font.pixelSize: Core.UiStyle.fontCaption
        font.weight: Font.DemiBold
        font.letterSpacing: root.mutedStatus ? 0.0 : 0.5
    }
}
