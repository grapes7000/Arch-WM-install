import QtQuick
import QtQuick.Layouts
import "../../core" as Core

GlassCard {
    id: root

    default property alias bodyData: body.data
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property string statusText: ""
    property color toneColor: Core.Theme.accent
    property int contentPadding: 16
    property int contentSpacing: 12

    implicitHeight: content.implicitHeight + root.contentPadding * 2

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: root.contentPadding
        spacing: root.contentSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                visible: root.icon.length > 0
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: Math.max(9, Core.Theme.radius)
                color: Core.Theme.alphaColor(root.toneColor, 0.12)
                border.width: Core.Theme.borderWidth
                border.color: Core.Theme.alphaColor(root.toneColor, 0.24)

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: root.toneColor
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.shellFontSize + 5
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Core.Theme.foreground
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.shellFontSize + 3
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.subtitle.length > 0
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: Core.Theme.muted
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Math.max(9, Core.Theme.shellFontSize - 1)
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                visible: root.statusText.length > 0
                Layout.preferredWidth: statusLabel.implicitWidth + 16
                Layout.preferredHeight: 24
                radius: 12
                color: Core.Theme.alphaColor(root.toneColor, 0.10)
                border.width: Core.Theme.borderWidth
                border.color: Core.Theme.alphaColor(root.toneColor, 0.26)

                Text {
                    id: statusLabel
                    anchors.centerIn: parent
                    text: root.statusText
                    color: root.toneColor
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Math.max(9, Core.Theme.shellFontSize - 1)
                    font.bold: true
                }
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.contentSpacing
        }
    }
}
