import QtQuick
import "../../core" as Core

Rectangle {
    id: root

    property bool active: false
    property bool interactive: false
    property real fillAlphaBoost: 0
    property alias hoverHandler: hover
    property real bounce: 1.0

    // Homepage assembly motion. Every GlassCard participates by default, but
    // callers can disable it or provide an explicit order when a future
    // layout needs different choreography. The automatic order is derived
    // from the card's top-level column, so the left rail lands first, the
    // center follows, then the right rail.
    property bool assemblyEnabled: true
    property int assemblyOrder: -1
    property real revealProgress: 1.0
    readonly property int effectiveAssemblyOrder: root.assemblyOrder >= 0
        ? root.assemblyOrder : root.automaticAssemblyOrder()
    readonly property int assemblyDelay: Math.round(
        (35 + root.effectiveAssemblyOrder * 105) * Core.Theme.motionScale)
    readonly property real revealScale: 0.98 + (0.02 * root.revealProgress)
    readonly property real revealOffset: (1.0 - root.revealProgress)
        * -Math.round((42 + root.effectiveAssemblyOrder * 10) * Math.max(0.25, Core.Theme.motionScale))
    readonly property bool hostVisible: Window.visibility !== Window.Hidden

    signal clicked()

    function automaticAssemblyOrder() {
        const column = root.parent
        const row = column ? column.parent : null
        if (!column || !row || Number(row.width) <= 0)
            return 0

        const midpoint = Number(column.x) + Number(column.width) / 2
        const ratio = midpoint / Number(row.width)
        if (ratio < 0.28)
            return 0
        if (ratio < 0.78)
            return 1
        return 2
    }

    function resetAssembly() {
        revealDelay.stop()
        revealAnimation.stop()
        root.revealProgress = root.assemblyEnabled && Core.Theme.motionScale > 0.05 ? 0.0 : 1.0
    }

    function startAssembly() {
        revealDelay.stop()
        revealAnimation.stop()
        if (!root.assemblyEnabled || Core.Theme.motionScale <= 0.05) {
            root.revealProgress = 1.0
            return
        }
        root.revealProgress = 0.0
        revealDelay.restart()
    }

    Component.onCompleted: {
        if (root.hostVisible)
            Qt.callLater(root.startAssembly)
        else
            root.resetAssembly()
    }

    onHostVisibleChanged: {
        if (root.hostVisible)
            Qt.callLater(root.startAssembly)
        else
            root.resetAssembly()
    }

    radius: Core.Theme.homepageCardRadius
    color: {
        const token = root.active ? Core.Theme.surfaceElevated : Core.Theme.surfaceRaised
        const c = Qt.color(token)
        const alpha = Math.min(1.0, Core.Theme.homepageCardOpacity + root.fillAlphaBoost
            + (root.active ? 0.16 : 0))
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }
    border.width: root.active ? Math.max(2, Core.Theme.borderWidth) : Core.Theme.borderWidth
    border.color: root.active
        ? Core.Theme.accent
        : (Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor)
    opacity: Math.max(0.0, Math.min(1.0, root.revealProgress))
    scale: (root.interactive && hover.hovered ? 1.015 : 1.0) * root.bounce * root.revealScale

    // Translate is intentionally used instead of animating y. GlassCard is
    // frequently owned by Qt Quick Layouts, which control its geometry; a
    // render transform gives us the falling/settling motion without fighting
    // the layout engine or leaving cards at incorrect coordinates.
    transform: Translate {
        y: root.revealOffset
    }

    Timer {
        id: revealDelay
        interval: root.assemblyDelay
        repeat: false
        onTriggered: revealAnimation.restart()
    }

    NumberAnimation {
        id: revealAnimation
        target: root
        property: "revealProgress"
        to: 1.0
        duration: Math.round(
            Math.max(280, Core.Theme.homepageTransitionMs) * Math.max(0.25, Core.Theme.motionScale))
        easing.type: Core.Theme.animationProfile === "snappy"
            ? Easing.OutCubic : Easing.OutBack
        easing.overshoot: 1.45
    }

    Behavior on scale {
        enabled: root.revealProgress >= 0.999
        NumberAnimation {
            duration: Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale)
            easing.type: Core.Theme.animationProfile === "snappy" ? Easing.OutQuad : Easing.OutCubic
        }
    }

    Behavior on border.color {
        ColorAnimation { duration: Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale) }
    }

    HoverHandler {
        id: hover
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        enabled: root.interactive
        gesturePolicy: TapHandler.WithinBounds
        onTapped: root.clicked()
        onPressedChanged: {
            if (tap.pressed) {
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
        target: root
        property: "bounce"
        to: 0.97
        duration: 60
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: bounceAnim
        target: root
        property: "bounce"
        to: 1.0
        duration: 140
        easing.type: Easing.OutBack
        easing.overshoot: 2.2
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, parent.radius - 1)
        color: root.interactive && hover.hovered
            ? Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.24)
            : "transparent"
        opacity: root.interactive && hover.hovered ? 1 : 0
        border.width: 1
        // Subtle by default; a stronger accent-tinted border only appears
        // while hovering an interactive card, so borders read as feedback
        // rather than constant visual noise.
        border.color: hover.hovered
            ? Core.Theme.alphaColor(Core.Theme.accent, 0.55)
            : Core.Theme.alphaColor(Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor, 0.22)
        Behavior on opacity {
            NumberAnimation { duration: Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale) }
        }
    }
}
