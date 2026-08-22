import QtQuick
import QtQuick.Effects
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
    readonly property bool precision: Core.UiStyle.flatSurfaces

    property bool assemblyEnabled: true
    property real assemblyOrder: -1
    property string assemblyDirection: "auto"
    property real revealProgress: 1.0
    readonly property real effectiveAssemblyOrder: root.assemblyOrder >= 0
        ? root.assemblyOrder : root.automaticAssemblyOrder()
    readonly property string effectiveAssemblyDirection: root.assemblyDirection !== "auto"
        ? root.assemblyDirection : root.automaticAssemblyDirection()
    readonly property int assemblyDelay: Math.round(
        (root.precision ? 18 + root.effectiveAssemblyOrder * 36
                        : 32 + root.effectiveAssemblyOrder * 112)
        * Core.Theme.motionScale)
    readonly property real revealScale: root.precision
        ? 1.0
        : 0.975 + (0.025 * root.revealProgress)
    readonly property real revealDistance: Math.round(
        (root.precision ? 10 : 50 + Math.min(16, root.effectiveAssemblyOrder * 1.8))
        * Math.max(0.25, Core.Theme.motionScale))
    readonly property real landingPulse: root.precision ? 0.0 : Math.max(
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
        if (metrics.columnRatio >= 0.28 && metrics.columnRatio < 0.78) {
            if (metrics.topmost)
                return 0
            return 4.4 + metrics.vertical * 0.8
        }
        if (metrics.columnRatio >= 0.78)
            return 0.9 + metrics.vertical * 3.3
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
        // Homepage cards should read as solid desktop surfaces, not washed-out glass.
        const baseAlpha = root.precision
            ? 0.88
            : Math.max(0.84, Core.Theme.homepageCardOpacity)
        const alpha = Math.min(1.0, baseAlpha + root.fillAlphaBoost
            + (root.active ? (root.precision ? 0.06 : 0.10) : 0))
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }
    border.width: Core.UiStyle.borderWidth
    border.color: root.active
        ? Core.Theme.alphaColor(Core.Theme.accent, root.precision ? 0.48 : 1.0)
        : Core.Theme.alphaColor(
            Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor,
            root.precision ? 0.48 : 1.0
        )
    opacity: Math.max(0.0, Math.min(1.0, root.revealProgress))
    scale: (root.interactive && hover.hovered && !root.precision ? 1.015 : 1.0)
        * root.bounce * root.revealScale

    transform: Translate {
        x: root.revealOffsetX
        y: root.revealOffsetY
    }

    // Real blurred shadow. This replaces the old translated/rotated duplicate
    // rectangles that looked like offset cards rather than depth.
    RectangularShadow {
        anchors.fill: parent
        z: -1
        radius: root.radius
        blur: root.precision ? 18 : 26
        spread: root.precision ? 0 : 1
        offset: Qt.vector2d(0, root.precision ? 5 : 7)
        color: Core.Theme.alphaColor(
            Core.Theme.shadowColor,
            Core.Theme.shadowEnabled
                ? Math.min(root.precision ? 0.28 : 0.38,
                    Math.max(0.16, Core.Theme.shadowOpacity))
                : 0
        )
        visible: Core.Theme.shadowEnabled
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
            (root.precision ? 140 : Math.max(350, Core.Theme.homepageTransitionMs))
            * Math.max(0.25, Core.Theme.motionScale))
        easing.type: root.precision
            ? Easing.OutCubic
            : (Core.Theme.animationProfile === "snappy" ? Easing.OutCubic : Easing.OutBack)
        easing.overshoot: root.precision ? 0.0 : 1.45
    }

    Behavior on scale {
        enabled: root.revealProgress >= 0.999
        NumberAnimation {
            duration: root.precision ? 90 : Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on border.color {
        ColorAnimation { duration: root.precision ? 100 : Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale) }
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
        to: root.precision ? 0.99 : 0.97
        duration: root.precision ? 45 : 60
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: bounceAnim
        target: root
        property: "bounce"
        to: 1.0
        duration: root.precision ? 80 : 140
        easing.type: root.precision ? Easing.OutCubic : Easing.OutBack
        easing.overshoot: root.precision ? 0.0 : 2.2
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: root.radius + 1
        color: "transparent"
        border.width: Core.UiStyle.borderWidth
        border.color: Core.Theme.alphaColor(Core.Theme.accent, 0.8)
        opacity: root.landingPulse * 0.55
        visible: !root.precision
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, parent.radius - 1)
        color: root.interactive && hover.hovered
            ? Core.Theme.alphaColor(Core.Theme.surfaceHover, root.precision ? 0.14 : 0.24)
            : "transparent"
        opacity: root.interactive && hover.hovered ? 1 : 0
        border.width: Core.UiStyle.borderWidth
        border.color: hover.hovered
            ? Core.Theme.alphaColor(Core.Theme.accent, root.precision ? 0.32 : 0.55)
            : Core.Theme.alphaColor(Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor, 0.22)
        Behavior on opacity {
            NumberAnimation { duration: root.precision ? 90 : Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale) }
        }
    }
}
