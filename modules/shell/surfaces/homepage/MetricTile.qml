import QtQuick
import QtQuick.Layouts
import "../../core" as Core

Rectangle {
    id: root

    property string label: "Metric"
    property string valueText: "--"
    property string detail: ""
    property string icon: ""
    property real value: 0
    property bool showProgress: true
    property string tone: "accent"
    readonly property color toneColor: root.tone === "secondary"
        ? Qt.color(Core.Theme.accent2)
        : (root.tone === "urgent" ? Qt.color(Core.Theme.urgent) : Qt.color(Core.Theme.accent))

    implicitWidth: 120
    implicitHeight: 88
    radius: Math.max(10, Core.Theme.homepageCardRadius - 5)
    color: Core.Theme.alphaColor(Core.Theme.surfaceElevated, 0.58)
    border.width: 1
    border.color: Core.Theme.alphaColor(Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor, 0.58)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 11
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                visible: root.icon.length > 0
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 8
                color: Core.Theme.alphaColor(root.toneColor, 0.12)

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: root.toneColor
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.label
                color: Core.Theme.muted
                font.family: Core.Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: root.valueText
                color: Core.Theme.foreground
                font.family: Core.Theme.fontFamily
                font.pixelSize: 20
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                visible: root.detail.length > 0
                text: root.detail
                color: Core.Theme.muted
                font.family: Core.Theme.fontFamily
                font.pixelSize: 9
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
            }
        }

        Rectangle {
            visible: root.showProgress
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            radius: 2
            color: Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.72)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, root.value)) / 100
                height: parent.height
                radius: parent.radius
                color: root.toneColor
                Behavior on width {
                    NumberAnimation {
                        duration: Math.round(220 * Core.Theme.motionScale)
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
