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
    property int contentPadding: Core.UiStyle.spacingMd
    property int contentSpacing: Core.UiStyle.spacingSm
    property bool showHeader: root.eyebrow.length > 0 || root.title.length > 0
        || root.subtitle.length > 0 || root.icon.length > 0 || root.statusText.length > 0

    bounce: Core.UiStyle.quietButtons
        ? 1.0
        : (cardHover.hovered && root.revealProgress >= 0.999 ? 1.006 : 1.0)

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
            spacing: Core.UiStyle.spacingSm

            Text {
                visible: root.eyebrow.length > 0
                text: root.eyebrow.toUpperCase()
                color: Core.Theme.accent
                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.UiStyle.fontCaption
                font.weight: Font.DemiBold
                font.letterSpacing: Core.UiStyle.quietButtons ? 0.4 : 1.2
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
            spacing: Core.UiStyle.spacingSm

            Rectangle {
                visible: root.icon.length > 0
                Layout.preferredWidth: root.heroStyle ? Core.UiStyle.controlHeight : Core.UiStyle.controlHeightCompact
                Layout.preferredHeight: Layout.preferredWidth
                radius: Core.UiStyle.radiusControl
                color: Core.UiStyle.flatSurfaces
                    ? "transparent"
                    : Core.Theme.alphaColor(Core.Theme.accent,
                        cardHover.hovered ? (root.heroStyle ? 0.22 : 0.17) : (root.heroStyle ? 0.16 : 0.11))
                border.width: Core.UiStyle.borderWidth
                border.color: Core.Theme.alphaColor(
                    Core.Theme.accent,
                    Core.UiStyle.flatSurfaces ? 0.24 : (cardHover.hovered ? 0.42 : 0.22)
                )

                Behavior on color { ColorAnimation { duration: Core.Theme.animationMs } }
                Behavior on border.color { ColorAnimation { duration: Core.Theme.animationMs } }

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: Core.Theme.accent
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: root.heroStyle ? Core.UiStyle.iconSize + 2 : Core.UiStyle.iconSize
                    scale: Core.UiStyle.quietButtons ? 1.0 : (cardHover.hovered ? 1.06 : 1.0)
                    Behavior on scale {
                        NumberAnimation { duration: Core.Theme.animationMs; easing.type: Easing.OutCubic }
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
                    font.pixelSize: root.heroStyle ? Core.UiStyle.fontTitle : Core.UiStyle.fontSection
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.subtitle.length > 0
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: Core.Theme.muted
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.UiStyle.fontCaption
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
        height: Core.UiStyle.borderWidth
        radius: 0
        color: Core.Theme.alphaColor(Core.Theme.accent,
            root.active ? 0.72 : (cardHover.hovered ? 0.44 : 0.18))
        opacity: root.active ? 1.0 : (cardHover.hovered ? 0.72 : 0.36)

        Behavior on color { ColorAnimation { duration: Core.Theme.animationMs } }
        Behavior on opacity { NumberAnimation { duration: Core.Theme.animationMs } }
    }
}
