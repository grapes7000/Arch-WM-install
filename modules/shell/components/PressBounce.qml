import QtQuick
import "../core" as Core

// Shared press feedback. Motion personality comes from the UI-style contract:
// Win95 is static, Precision restrained, Legacy playful.
Item {
    id: root

    property Item target: parent
    property bool pressed: false
    property real pressScale: Core.UiStyle.pressScale
    property int pressDuration: Core.UiStyle.motionFastMs
    property int reboundDuration: Core.UiStyle.motionNormalMs

    onPressedChanged: {
        if (Core.UiStyle.motionNone) {
            pressAnim.stop()
            reboundAnim.stop()
            if (root.target) root.target.scale = 1.0
            return
        }
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
        easing.type: Core.UiStyle.motionPlayful ? Easing.OutBack : Easing.OutCubic
        easing.overshoot: Core.UiStyle.releaseOvershoot
    }
}
