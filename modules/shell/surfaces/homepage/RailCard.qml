import QtQuick
import QtQuick.Layouts
import "../../core" as Core

GlassCard {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    signal activated()

    implicitHeight: 92
    interactive: true

    onClicked: root.activated()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Text {
            text: root.icon
            color: root.active ? Core.Theme.accent : Core.Theme.accent2
            font.pixelSize: 28
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Core.Theme.foreground
                font.pixelSize: 17
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.subtitle
                color: Core.Theme.muted
                font.pixelSize: 14
                elide: Text.ElideRight
            }
        }
    }
}
