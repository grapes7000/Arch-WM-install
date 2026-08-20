import QtQuick
import "../../core" as Core

Rectangle {
    id: root

    property bool active: false
    property bool interactive: false
    property real fillAlphaBoost: 0
    property alias hoverHandler: hover
    property real bounce: 1.0
    property bool angledShadow: false
    property bool superDraggable: false
    readonly property bool dragging: superDrag.active
    readonly property real depthOffset: Math.max(7, Math.min(14,
        Math.round(Core.Theme.shadowRadius * 0.52)))

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
        (32 + root.effectiveAssemblyOrder * 112) * Core.Theme.motionScale)
    readonly property real revealScale: 0.975 + (0.025 * root.revealProgress)
    readonly property real revealDistance: Math.round(
        (50 + Math.min(16, root.effectiveAssemblyOrder * 1.8))
        * Math.max(0.25, Core.Theme.motionScale))
    readonly property real landingPulse: Math.max(
        0.0, 1.0 - Math.abs(root.revealProgress - 0.84) * 7.0)
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
    z: root.dragging ? 100 : 1
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

    // Two theme-driven, diagonally offset silhouettes make each enabled card
    // read as a physical layer. They remain children of the card, so they move
    // with it and never become separately interactive.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Core.Theme.alphaColor(Core.Theme.shadowColor,
            Math.min(0.54, Core.Theme.shadowOpacity * 0.82))
        border.width: Math.max(1, Core.Theme.borderWidth)
        border.color: Core.Theme.alphaColor(Core.Theme.shadowColor,
            Math.min(0.66, Core.Theme.shadowOpacity))
        visible: root.angledShadow && Core.Theme.shadowEnabled
        z: -2
        transform: [
            Translate {
                x: root.depthOffset
                y: root.depthOffset
            },
            Rotation {
                origin.x: width / 2
                origin.y: height / 2
                angle: 1.15
            }
        ]
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: Math.max(1, Core.Theme.borderWidth)
        border.color: Core.Theme.alphaColor(Core.Theme.accent2,
            Math.min(0.32, 0.10 + Core.Theme.shadowOpacity * 0.28))
        visible: root.angledShadow && Core.Theme.shadowEnabled
        z: -1
        transform: [
            Translate {
                x: -Math.max(3, root.depthOffset * 0.36)
                y: Math.max(3, root.depthOffset * 0.44)
            },
            Rotation {
                origin.x: width / 2
                origin.y: height / 2
                angle: -0.72
            }
        ]
    }

    DragHandler {
        id: superDrag
        enabled: root.superDraggable
        target: root
        acceptedButtons: Qt.LeftButton
        acceptedModifiers: Qt.MetaModifier
        cursorShape: active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        xAxis.minimum: 0
        xAxis.maximum: root.parent ? Math.max(0, root.parent.width - root.width) : 0
        yAxis.minimum: 0
        yAxis.maximum: root.parent ? Math.max(0, root.parent.height - root.height) : 0
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
            Math.max(350, Core.Theme.homepageTransitionMs) * Math.max(0.25, Core.Theme.motionScale))
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

    // A brief accent flash follows each card through the last part of its
    // landing. It is progress-derived, so it cannot leave a timer or looping
    // animation running once the card has settled.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: root.radius + 1
        color: "transparent"
        border.width: 1
        border.color: Core.Theme.alphaColor(Core.Theme.accent, 0.8)
        opacity: root.landingPulse * 0.55
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
