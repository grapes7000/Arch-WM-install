import QtQuick
import "../core" as Core

// Shared press feedback. Precision keeps motion almost imperceptible and
// settles linearly; legacy profiles retain the springier bounce.
Item {
    id: root

    property Item target: parent
    property bool pressed: false
    readonly property bool quiet: Core.UiStyle.quietButtons
    property real pressScale: quiet ? 0.99 : 0.94
    property int pressDuration: quiet ? 45 : 60
    property int reboundDuration: quiet ? 80 : 140

    onPressedChanged: {
        if (pressed) {
            reboundAnim.stop()
            pressAnim.restart()
        } else {
            pressAnim.stop()
            reboundAnim.restart()
        }
    }

    NumberAnimation {
        id: pressAnim
        target: root.target
        property: "scale"
        to: root.pressScale
        duration: root.pressDuration
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: reboundAnim
        target: root.target
        property: "scale"
        to: 1.0
        duration: root.reboundDuration
        easing.type: root.quiet ? Easing.OutCubic : Easing.OutBack
        easing.overshoot: root.quiet ? 0.0 : 2.2
    }
}
