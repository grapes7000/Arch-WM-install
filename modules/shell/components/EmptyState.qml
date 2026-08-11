import QtQuick
import QtQuick.Layouts
import "../core" as Core

Rectangle {
    id: root

    property string icon: "󰇘"
    property string message: "Nothing to show"

    readonly property color __fg: Qt.color(Core.Theme.foreground)

    implicitHeight: col.implicitHeight + 24
    radius: Math.max(6, Core.Theme.radius - 2)
    color: Qt.rgba(__fg.r, __fg.g, __fg.b, 0.04)
    border.width: 1
    border.color: Qt.rgba(__fg.r, __fg.g, __fg.b, 0.06)
    opacity: 0.45

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: 6

        Text {
            Layout.alignment: Qt.AlignHCenter
            font.family: Core.Theme.fontFamily
            text: root.icon
            color: Core.Theme.muted
            font.pixelSize: 25
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            font.family: Core.Theme.fontFamily
            text: root.message
            color: Core.Theme.muted
            font.pixelSize: 14
        }
    }
}
