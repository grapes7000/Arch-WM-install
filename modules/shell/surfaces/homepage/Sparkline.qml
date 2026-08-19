import QtQuick
import "../../core" as Core

Canvas {
    id: root

    property var samples: []
    property real maximum: 100
    property color lineColor: Qt.color(Core.Theme.accent)
    property bool fillArea: true
    property real lineWidth: 2

    implicitWidth: 180
    implicitHeight: 44

    onSamplesChanged: requestPaint()
    onMaximumChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        const points = Array.isArray(root.samples) ? root.samples : []
        if (points.length < 2 || width <= 0 || height <= 0)
            return

        const maxValue = Math.max(1, Number(root.maximum))
        const padding = 2
        const usableWidth = Math.max(1, width - padding * 2)
        const usableHeight = Math.max(1, height - padding * 2)
        const step = usableWidth / Math.max(1, points.length - 1)

        function pointX(index) {
            return padding + index * step
        }

        function pointY(value) {
            const normalized = Math.max(0, Math.min(1, Number(value) / maxValue))
            return padding + usableHeight * (1 - normalized)
        }

        if (root.fillArea) {
            ctx.beginPath()
            ctx.moveTo(pointX(0), height - padding)
            for (let i = 0; i < points.length; ++i)
                ctx.lineTo(pointX(i), pointY(points[i]))
            ctx.lineTo(pointX(points.length - 1), height - padding)
            ctx.closePath()
            ctx.fillStyle = root.lineColor
            ctx.globalAlpha = 0.10
            ctx.fill()
            ctx.globalAlpha = 1.0
        }

        ctx.beginPath()
        for (let i = 0; i < points.length; ++i) {
            if (i === 0)
                ctx.moveTo(pointX(i), pointY(points[i]))
            else
                ctx.lineTo(pointX(i), pointY(points[i]))
        }
        ctx.strokeStyle = root.lineColor
        ctx.lineWidth = root.lineWidth
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        ctx.stroke()
    }
}
