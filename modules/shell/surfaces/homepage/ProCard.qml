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

    // Professional cards respond to pointer presence even when they are not
    // clickable. This is passive lighting/elevation only; it never steals taps
    // from controls inside the card.
    bounce: cardHover.hovered && root.revealProgress >= 0.999 ? 1.006 : 1.0

    // A parent layout may request a compact preferred height, but it must
    // never compress a card below the space needed by its header and body.
    implicitHeight: frame.implicitHeight + root.contentPadding * 2
    Layout.minimumHeight: implicitHeight

    HoverHandler {
        id: cardHover
        blocking: false
    }

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
                color: Core.Theme.alphaColor(Core.Theme.accent,
                    cardHover.hovered ? (root.heroStyle ? 0.22 : 0.17) : (root.heroStyle ? 0.16 : 0.11))
                border.width: 1
                border.color: Core.Theme.alphaColor(Core.Theme.accent, cardHover.hovered ? 0.42 : 0.22)

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: Core.Theme.accent
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: root.heroStyle ? 20 : 17
                    scale: cardHover.hovered ? 1.06 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
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
        height: cardHover.hovered ? 2 : 1
        radius: 1
        color: Core.Theme.alphaColor(Core.Theme.accent, cardHover.hovered ? 0.62 : 0.26)
        opacity: root.active ? 1.0 : (cardHover.hovered ? 0.82 : 0.42)

        Behavior on height { NumberAnimation { duration: 120 } }
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }
}
