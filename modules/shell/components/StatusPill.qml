import QtQuick
import "../core" as Core

Rectangle {
    id: root

    property bool active: false
    property string activeLabel: "ON"
    property string inactiveLabel: "OFF"
    property color activeColor: Core.Theme.accent
    property bool pulse: true

    property bool pulseState: false

    readonly property color __fg: Qt.color(Core.Theme.foreground)

    width: label.implicitWidth + 20
    height: label.implicitHeight + 6
    radius: 999
    color: active ? activeColor : Qt.rgba(__fg.r, __fg.g, __fg.b, 0.06)
    opacity: (active && pulse) ? (pulseState ? 1.0 : 0.6) : 1.0

    Behavior on opacity {
        NumberAnimation { duration: 750; easing.type: Easing.InOutQuad }
    }

    Timer {
        running: root.active && root.pulse
        interval: 1500
        repeat: true
        onTriggered: root.pulseState = !root.pulseState
    }

    Text {
        id: label
        font.family: Core.Theme.fontFamily
        anchors.centerIn: parent
        text: root.active ? root.activeLabel : root.inactiveLabel
        color: root.active ? Core.Theme.background : Core.Theme.muted
        font.pixelSize: 8
        font.bold: true
        font.letterSpacing: 0.5
    }
}
