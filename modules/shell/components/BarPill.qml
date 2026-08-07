import QtQuick
import "../core" as Core

// Pill-shaped background used by bar widgets. Renders a rounded rectangle
// slightly more contrasting than the bar surface, and owns the whole click
// area plus the press/release feedback animation (shrink+dim on press,
// snappy overshoot bounce on release) so every clickable widget behaves the
// same way.
Rectangle {
    id: root

    property bool clickable: true
    property int horizontalPadding: 10
    property int verticalPadding: 4

    signal clicked()

    radius: height / 2
    color: Core.Theme.data && Core.Theme.data.dark
        ? Qt.lighter(Core.Theme.surface, 1.45)
        : Qt.darker(Core.Theme.surface, 1.15)
    opacity: mouseArea.pressed ? 0.82 : 1.0
    transformOrigin: Item.Center

    Behavior on opacity {
        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: root.clickable
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
        onPressedChanged: {
            if (pressed) {
                bounceAnim.stop()
                root.scale = 0.96
            } else {
                bounceAnim.restart()
            }
        }
    }

    SequentialAnimation {
        id: bounceAnim
        NumberAnimation { target: root; property: "scale"; to: 1.08; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "scale"; to: 1.0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 3 }
    }
}
