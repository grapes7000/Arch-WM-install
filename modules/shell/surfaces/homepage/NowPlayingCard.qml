import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../../core" as Core
import "../../components" as Components
import "../../services" as Services

OrbitCard {
    id: root

    readonly property bool playing: Services.MprisService.status === "Playing"
    readonly property bool available: Services.MprisService.status !== "Stopped"

    title: "Now Playing"
    subtitle: root.available ? Services.MprisService.status : "Waiting for a player"
    icon: "󰎈"
    statusText: root.playing ? "PLAYING" : (root.available ? "PAUSED" : "IDLE")
    toneColor: root.playing ? Core.Theme.accent : Core.Theme.muted
    contentPadding: 16
    contentSpacing: 12

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 14

        ClippingRectangle {
            Layout.preferredWidth: 112
            Layout.preferredHeight: 112
            radius: Math.max(12, Core.Theme.homepageCardRadius - 3)
            color: Core.Theme.alphaColor(Core.Theme.surfaceOverlay, 0.56)
            border.width: Core.Theme.borderWidth
            border.color: Core.Theme.alphaColor(
                Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor, 0.42)

            Image {
                id: artwork
                anchors.fill: parent
                source: root.available ? Services.MprisService.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: artwork.status !== Image.Ready
                text: root.available ? "󰝚" : "󰎊"
                color: root.available ? Core.Theme.accent : Core.Theme.muted
                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.shellFontSize + 17
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 7

            Text {
                Layout.fillWidth: true
                text: Services.MprisService.title || "Nothing playing"
                color: Core.Theme.foreground
                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.shellFontSize + 3
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: Services.MprisService.artist || "Open a media player to begin"
                color: Core.Theme.muted
                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.shellFontSize
                elide: Text.ElideRight
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                opacity: root.playing ? 1 : 0.46

                Row {
                    anchors.fill: parent
                    spacing: 3

                    Repeater {
                        model: Services.CavaService.bars

                        Rectangle {
                            required property real modelData
                            required property int index
                            width: Math.max(2, (parent.width
                                - (Services.CavaService.bars.length - 1) * parent.spacing)
                                / Math.max(1, Services.CavaService.bars.length))
                            height: root.playing ? Math.max(3, parent.height * modelData) : 3
                            anchors.bottom: parent.bottom
                            radius: width / 2
                            color: index % 2 ? Core.Theme.accent2 : Core.Theme.accent

                            Behavior on height {
                                NumberAnimation {
                                    duration: Math.round(70 * Core.Theme.motionScale)
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }
                MediaButton {
                    glyph: "󰒮"
                    enabledState: Services.MprisService.canPrev
                    onTriggered: Services.MprisService.previous()
                }
                MediaButton {
                    glyph: root.playing ? "󰏤" : "󰐊"
                    highlighted: true
                    enabledState: root.available
                    onTriggered: Services.MprisService.playPause()
                }
                MediaButton {
                    glyph: "󰒭"
                    enabledState: Services.MprisService.canNext
                    onTriggered: Services.MprisService.next()
                }
                Item { Layout.fillWidth: true }
            }
        }
    }

    component MediaButton: Item {
        id: mediaButton
        required property string glyph
        property bool highlighted: false
        property bool enabledState: true
        signal triggered()

        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        opacity: mediaButton.enabledState ? 1 : 0.38

        Rectangle {
            anchors.centerIn: parent
            width: mediaButton.highlighted ? 38 : 32
            height: width
            radius: width / 2
            color: mediaButton.highlighted
                ? Core.Theme.alphaColor(Core.Theme.accent, 0.18)
                : Core.Theme.alphaColor(Core.Theme.surfaceHover, buttonHover.hovered ? 0.56 : 0.0)
            border.width: mediaButton.highlighted ? Core.Theme.borderWidth : 0
            border.color: Core.Theme.alphaColor(Core.Theme.accent, 0.42)

            Text {
                anchors.centerIn: parent
                text: mediaButton.glyph
                color: mediaButton.highlighted ? Core.Theme.accent : Core.Theme.foreground
                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.Theme.shellFontSize + 5
            }
        }

        HoverHandler {
            id: buttonHover
            enabled: mediaButton.enabledState
            cursorShape: mediaButton.enabledState ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
        TapHandler {
            id: buttonTap
            enabled: mediaButton.enabledState
            onTapped: mediaButton.triggered()
        }
        Components.PressBounce { target: mediaButton; pressed: buttonTap.pressed }
    }
}
