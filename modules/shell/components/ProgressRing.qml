import QtQuick
import "../core" as Core

Item {
    id: root

    property real percent: 0
    property color ringColor: Core.Theme.accent
    property bool showLabel: true
    property string label: Math.round(percent * 100) + "%"

    width: 42
    height: 42

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            var cx = width / 2
            var cy = height / 2
            var r = (Math.min(width, height) - 6) / 2
            var fg = Qt.color(Core.Theme.foreground)
            ctx.clearRect(0, 0, width, height)

            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
            ctx.lineWidth = 4
            ctx.strokeStyle = Qt.rgba(fg.r, fg.g, fg.b, 0.06)
            ctx.stroke()

            if (root.percent > 0) {
                ctx.beginPath()
                var start = -Math.PI / 2
                ctx.arc(cx, cy, r, start, start + 2 * Math.PI * root.percent)
                ctx.lineWidth = 4
                ctx.strokeStyle = root.ringColor
                ctx.lineCap = "round"
                ctx.stroke()
            }
        }
    }

    onPercentChanged: canvas.requestPaint()
    onRingColorChanged: canvas.requestPaint()

    Text {
        visible: root.showLabel
        font.family: Core.Theme.fontFamily
        anchors.centerIn: parent
        text: root.label
        color: Core.Theme.foreground
        font.pixelSize: 10
        font.bold: true
    }
}
