import QtQuick

// Drop this inside any clickable Item to give it the shrink+dim-on-press,
// snappy-overshoot-on-release feel, without drawing any background of its
// own. Uses a non-blocking TapHandler so it never steals the click from an
// existing MouseArea/TapHandler on the same item.
Item {
    id: root
    anchors.fill: parent

    property Item target: parent
    property real pressScale: 0.94
    property real overshootScale: 1.08
    // Kept short and un-eased-in so the press reads as immediate (tracking
    // real mouse-down timing) and the rebound fires right at mouse-up.
    property int pressDuration: 60
    property int reboundPeakDuration: 70
    property int reboundSettleDuration: 110

    TapHandler {
        id: tap
        gesturePolicy: TapHandler.WithinBounds
        onPressedChanged: {
            if (pressed) {
                bounceAnim.stop()
                pressAnim.restart()
            } else {
                pressAnim.stop()
                bounceAnim.restart()
            }
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

    SequentialAnimation {
        id: bounceAnim
        NumberAnimation {
            target: root.target
            property: "scale"
            to: root.overshootScale
            duration: root.reboundPeakDuration
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root.target
            property: "scale"
            to: 1.0
            duration: root.reboundSettleDuration
            easing.type: Easing.OutBack
            easing.overshoot: 3
        }
    }
}
