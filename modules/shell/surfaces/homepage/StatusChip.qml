import QtQuick
import QtQuick.Layouts
import "../../core" as Core

Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property string tone: "accent"
    readonly property color toneColor: {
        if (root.tone === "urgent" || root.tone === "danger")
            return Qt.color(Core.Theme.urgent)
        if (root.tone === "secondary" || root.tone === "good")
            return Qt.color(Core.Theme.accent2)
        if (root.tone === "muted")
            return Qt.color(Core.Theme.muted)
        return Qt.color(Core.Theme.accent)
    }

    implicitWidth: chipRow.implicitWidth + 14
    implicitHeight: 24
    radius: 12
    color: Qt.rgba(root.toneColor.r, root.toneColor.g, root.toneColor.b, 0.12)
    border.width: 1
    border.color: Qt.rgba(root.toneColor.r, root.toneColor.g, root.toneColor.b, 0.34)
    visible: root.text.length > 0

    RowLayout {
        id: chipRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            visible: root.icon.length > 0
            text: root.icon
            color: root.toneColor
            font.family: Core.Theme.fontFamily
            font.pixelSize: 11
        }

        Rectangle {
            visible: root.icon.length === 0
            Layout.preferredWidth: 5
            Layout.preferredHeight: 5
            radius: 3
            color: root.toneColor
        }

        Text {
            text: root.text
            color: Core.Theme.foreground
            font.family: Core.Theme.fontFamily
            font.pixelSize: 10
            font.bold: true
        }
    }
}
