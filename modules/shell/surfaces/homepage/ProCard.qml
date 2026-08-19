import QtQuick
import QtQuick.Layouts
import "../../core" as Core

GlassCard {
    id: root

    default property alias bodyData: body.data
    property string eyebrow: ""
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property string statusText: ""
    property string statusTone: "accent"
    property bool heroStyle: false
    property int contentPadding: 16
    property int contentSpacing: 10
    property bool showHeader: root.eyebrow.length > 0 || root.title.length > 0
        || root.subtitle.length > 0 || root.icon.length > 0 || root.statusText.length > 0

    // A parent layout may request a compact preferred height, but it must
    // never compress a card below the space needed by its header and body.
    // This keeps metric tiles and control rows inside the rounded surface.
    implicitHeight: frame.implicitHeight + root.contentPadding * 2
    Layout.minimumHeight: implicitHeight

    ColumnLayout {
        id: frame
        anchors.fill: parent
        anchors.margins: root.contentPadding
        spacing: root.contentSpacing

        RowLayout {
            visible: root.showHeader && (root.eyebrow.length > 0 || root.statusText.length > 0)
            Layout.fillWidth: true
            spacing: 8

            Text {
                visible: root.eyebrow.length > 0
                text: root.eyebrow.toUpperCase()
                color: Core.Theme.accent
                font.family: Core.Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.2
            }

            Item { Layout.fillWidth: true }

            StatusChip {
                visible: root.statusText.length > 0
                text: root.statusText
                tone: root.statusTone
            }
        }

        RowLayout {
            visible: root.showHeader && (root.title.length > 0 || root.subtitle.length > 0 || root.icon.length > 0)
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                visible: root.icon.length > 0
                Layout.preferredWidth: root.heroStyle ? 40 : 34
                Layout.preferredHeight: root.heroStyle ? 40 : 34
                radius: root.heroStyle ? 13 : 11
                color: Core.Theme.alphaColor(Core.Theme.accent, root.heroStyle ? 0.16 : 0.11)
                border.width: 1
                border.color: Core.Theme.alphaColor(Core.Theme.accent, 0.22)

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: Core.Theme.accent
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: root.heroStyle ? 20 : 17
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    visible: root.title.length > 0
                    Layout.fillWidth: true
                    text: root.title
                    color: Core.Theme.foreground
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: root.heroStyle ? 20 : 16
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.subtitle.length > 0
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: Core.Theme.muted
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: root.heroStyle ? 12 : 11
                    elide: Text.ElideRight
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

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        radius: 1
        color: Core.Theme.alphaColor(Core.Theme.accent, 0.26)
        opacity: root.active ? 1.0 : 0.42
    }
}
