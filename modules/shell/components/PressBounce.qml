import QtQuick

// Drop this next to any clickable Item to give it the shrink+dim-on-press,
// bouncy-settle-on-release feel. Deliberately does NOT own its own
// MouseArea/TapHandler: a second pointer handler sitting alongside the
// button's real one can grab-conflict with it in Qt6 and silently never
// fire. Instead, bind `pressed` to the existing MouseArea/TapHandler's own
// `pressed` property so there is exactly one thing tracking the press.
Item {
    id: root

    // Defaults to the immediate parent, which is right for icons wrapped
    // directly in a Text/Item; pass an explicit target for anything else.
    property Item target: parent
    property bool pressed: false
    property real pressScale: 0.94
    // Settles back to exactly 1.0 (the target's normal size) rather than
    // overshooting past it — the bounce comes from the OutBack easing
    // curve's own overshoot-and-settle character, not an inflated peak.
    property int pressDuration: 60
    property int reboundDuration: 140

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
        easing.type: Easing.OutBack
        easing.overshoot: 2.2
    }
}
