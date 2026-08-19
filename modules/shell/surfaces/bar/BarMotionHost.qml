import QtQuick
import "../../components" as Components
import "../../core" as Core

Item {
    id: root

    required property var entry
    required property string surfaceKind
    required property bool locked
    property var requestHandler: null
    property int entranceOrder: 0
    property real revealProgress: Core.Theme.motionScale <= 0.05 ? 1.0 : 0.0

    implicitWidth: host.implicitWidth
    implicitHeight: host.implicitHeight
    opacity: Math.max(0.0, Math.min(1.0, revealProgress))
    scale: (0.94 + 0.06 * revealProgress) * (hover.hovered ? 1.045 : 1.0)

    transform: [
        Translate {
            y: (1.0 - root.revealProgress) * -7
        },
        Translate {
            id: hoverLift
            y: hover.hovered && root.revealProgress >= 0.999 ? -2 : 0
            Behavior on y {
                NumberAnimation {
                    duration: Math.round(Math.max(70, Core.Theme.animationMs * 0.65) * Core.Theme.motionScale)
                    easing.type: Easing.OutCubic
                }
            }
        }
    ]

    Component.onCompleted: {
        if (Core.Theme.motionScale <= 0.05) {
            root.revealProgress = 1.0
            return
        }
        revealDelay.restart()
    }

    Timer {
        id: revealDelay
        interval: Math.round((24 + root.entranceOrder * 34) * Core.Theme.motionScale)
        repeat: false
        onTriggered: revealAnimation.restart()
    }

    NumberAnimation {
        id: revealAnimation
        target: root
        property: "revealProgress"
        from: 0.0
        to: 1.0
        duration: Math.round(Math.max(150, Core.Theme.animationMs) * Core.Theme.motionScale)
        easing.type: Easing.OutBack
        easing.overshoot: 1.25
    }

    Behavior on scale {
        enabled: root.revealProgress >= 0.999
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
