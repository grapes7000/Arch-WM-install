import QtQuick
import QtQuick.Layouts
import "../../core" as Core

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string valueText: "--"
    property real value: 0
    property color toneColor: Core.Theme.accent
    property bool showProgress: true

    implicitWidth: 150
    implicitHeight: 62

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: Math.max(8, Core.Theme.radius - 1)
                color: Core.Theme.alphaColor(root.toneColor, 0.12)

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: root.toneColor
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.shellFontSize + 3
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.label
                    color: Core.Theme.muted
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Math.max(9, Core.Theme.shellFontSize - 1)
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.valueText
                    color: Core.Theme.foreground
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.shellFontSize + 5
                    font.bold: true
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            visible: root.showProgress
            Layout.fillWidth: true
            Layout.preferredHeight: 3
            radius: 2
            color: Core.Theme.alphaColor(Core.Theme.surfaceOverlay, 0.72)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, root.value)) / 100
                height: parent.height
                radius: parent.radius
                color: root.toneColor

                Behavior on width {
                    NumberAnimation {
                        duration: Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale)
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
