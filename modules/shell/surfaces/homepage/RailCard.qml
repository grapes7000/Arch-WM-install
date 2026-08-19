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
    fillAlphaBoost: root.active ? 0.06 : 0

    onClicked: root.activated()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 11
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            radius: 12
            color: Core.Theme.alphaColor(root.active ? Core.Theme.accent : Core.Theme.accent2, root.active ? 0.16 : 0.10)
            border.width: 1
            border.color: Core.Theme.alphaColor(root.active ? Core.Theme.accent : Core.Theme.accent2, root.active ? 0.42 : 0.22)

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.active ? Core.Theme.accent : Core.Theme.accent2
                font.family: Core.Theme.fontFamily
                font.pixelSize: 19
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Core.Theme.foreground
                font.family: Core.Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.subtitle
                color: Core.Theme.muted
                font.family: Core.Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: root.active ? 22 : 18
            Layout.preferredHeight: root.active ? 22 : 18
            radius: width / 2
            color: root.active
                ? Core.Theme.alphaColor(Core.Theme.accent, 0.16)
                : "transparent"

            Text {
                anchors.centerIn: parent
                text: root.active ? "󰅂" : "󰅂"
                color: root.active ? Core.Theme.accent : Core.Theme.muted
                font.family: Core.Theme.fontFamily
                font.pixelSize: root.active ? 12 : 10
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: root.active ? Math.max(22, parent.height * 0.45) : 0
        radius: 2
        color: Core.Theme.accent
        opacity: root.active ? 1 : 0

        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
}
