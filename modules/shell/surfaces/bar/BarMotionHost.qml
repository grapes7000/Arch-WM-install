import QtQuick
import "../../components" as Components
import "../../core" as Core

Item {
    id: root

    property var entry: ({})
    required property string surfaceKind
    required property bool locked
    property var requestHandler: null
    property int entranceOrder: 0

    implicitWidth: host.implicitWidth
    implicitHeight: host.implicitHeight
    opacity: 1.0
    scale: hover.hovered ? 1.045 : 1.0

    transform: [
        Translate {
            id: entranceTranslate
            y: Core.Theme.motionScale <= 0.05 ? 0 : -6
        },
        Translate {
            id: hoverLift
            y: hover.hovered ? -2 : 0
            Behavior on y {
                NumberAnimation {
                    duration: Math.round(Math.max(70, Core.Theme.animationMs * 0.65) * Core.Theme.motionScale)
                    easing.type: Easing.OutCubic
                }
            }
        }
    ]

    // Entrance motion is deliberately fail-open: the widget is fully visible
    // before this timer ever runs. If a compositor/runtime skips the timer or
    // animation, the only failure mode is a harmless 6px offset rather than a
    // missing bar widget.
    Component.onCompleted: {
        if (Core.Theme.motionScale <= 0.05) {
            entranceTranslate.y = 0
            return
        }
        entranceDelay.restart()
    }

    Timer {
        id: entranceDelay
        interval: Math.round((24 + root.entranceOrder * 26) * Core.Theme.motionScale)
        repeat: false
        onTriggered: entranceAnimation.restart()
    }

    NumberAnimation {
        id: entranceAnimation
        target: entranceTranslate
        property: "y"
        from: -6
        to: 0
        duration: Math.round(Math.max(130, Core.Theme.animationMs * 0.9) * Core.Theme.motionScale)
        easing.type: Easing.OutBack
        easing.overshoot: 1.2
    }

    Behavior on scale {
        NumberAnimation {
            duration: Math.round(Math.max(80, Core.Theme.animationMs * 0.7) * Core.Theme.motionScale)
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        id: hover
    }

    Components.WidgetHost {
        id: host
        anchors.centerIn: parent
        widgetId: root.entry.widget || ""
        surfaceKind: root.surfaceKind
        instanceId: root.entry.instance || ""
        variant: root.entry.variant || "compact"
        settings: root.entry.settings || ({})
        locked: root.locked
        requestHandler: root.requestHandler
    }
}
