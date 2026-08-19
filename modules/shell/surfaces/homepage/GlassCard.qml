import QtQuick
import "../../core" as Core

Rectangle {
    id: root

    property bool active: false
    property bool interactive: false
    property real fillAlphaBoost: 0
    property alias hoverHandler: hover
    property real bounce: 1.0

    // Homepage assembly motion. Cards derive a clockwise reveal order and
    // entrance direction from their position in the three-column homepage:
    // top-center first, right rail top-to-bottom, lower center, then left rail
    // bottom-to-top. Callers can still override order/direction explicitly.
    property bool assemblyEnabled: true
    property real assemblyOrder: -1
    property string assemblyDirection: "auto"
    property real revealProgress: 1.0
    readonly property real effectiveAssemblyOrder: root.assemblyOrder >= 0
        ? root.assemblyOrder : root.automaticAssemblyOrder()
    readonly property string effectiveAssemblyDirection: root.assemblyDirection !== "auto"
        ? root.assemblyDirection : root.automaticAssemblyDirection()
    readonly property int assemblyDelay: Math.round(
        (45 + root.effectiveAssemblyOrder * 145) * Core.Theme.motionScale)
    readonly property real revealScale: 0.975 + (0.025 * root.revealProgress)
    readonly property real revealDistance: Math.round(
        (54 + Math.min(18, root.effectiveAssemblyOrder * 2))
        * Math.max(0.25, Core.Theme.motionScale))
    readonly property real revealOffsetX: {
        const remaining = 1.0 - root.revealProgress
        if (root.effectiveAssemblyDirection === "left")
            return -root.revealDistance * remaining
        if (root.effectiveAssemblyDirection === "right")
            return root.revealDistance * remaining
        return 0
    }
    readonly property real revealOffsetY: {
        const remaining = 1.0 - root.revealProgress
        if (root.effectiveAssemblyDirection === "top")
            return -root.revealDistance * remaining
        if (root.effectiveAssemblyDirection === "bottom")
            return root.revealDistance * remaining
        return 0
    }
    readonly property bool hostVisible: Window.visibility !== Window.Hidden

    signal clicked()

    function layoutMetrics() {
        const column = root.parent
        const row = column ? column.parent : null
        if (!column || !row || Number(row.width) <= 0 || Number(column.height) <= 0)
            return { valid: false, columnRatio: 0.5, vertical: 0.0, topmost: true }

        const columnMidpoint = Number(column.x) + Number(column.width) / 2
        const columnRatio = columnMidpoint / Number(row.width)
        const cardMidpoint = Number(root.y) + Number(root.height) / 2
        const vertical = Math.max(0.0, Math.min(1.0, cardMidpoint / Number(column.height)))
        const topThreshold = Math.max(12, Number(column.height) * 0.035)
        return {
            valid: true,
            columnRatio: columnRatio,
            vertical: vertical,
            topmost: Number(root.y) <= topThreshold
        }
    }

    function automaticAssemblyOrder() {
        const metrics = root.layoutMetrics()
        if (!metrics.valid)
            return 0

        // Center: the topmost card is the hero/primary card and always leads.
        // Remaining center cards follow the right rail before the left side.
        if (metrics.columnRatio >= 0.28 && metrics.columnRatio < 0.78) {
            if (metrics.topmost)
                return 0
            return 4.4 + metrics.vertical * 0.8
        }

        // Right rail proceeds downward after the hero.
        if (metrics.columnRatio >= 0.78)
            return 0.9 + metrics.vertical * 3.3

        // Left rail closes the clockwise loop from bottom back toward the top.
        return 5.1 + (1.0 - metrics.vertical) * 3.4
    }

    function automaticAssemblyDirection() {
        const metrics = root.layoutMetrics()
        if (!metrics.valid)
            return "top"
        if (metrics.columnRatio < 0.28)
            return "left"
        if (metrics.columnRatio >= 0.78)
            return "right"
        return metrics.topmost ? "top" : "bottom"
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

    // Translate is intentionally used instead of animating layout-owned x/y.
    // Qt Quick Layouts retain geometry ownership while cards visually slide
    // from their nearest screen-side and settle into their final positions.
    transform: Translate {
        x: root.revealOffsetX
        y: root.revealOffsetY
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
            Math.max(420, Core.Theme.homepageTransitionMs) * Math.max(0.25, Core.Theme.motionScale))
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
