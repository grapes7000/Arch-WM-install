import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components

Item {
    id: panel
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Core.UiStyle.spacingMd

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Core.UiStyle.spacingXs

            Text {
                font.family: Core.Theme.fontFamily
                text: Services.MprisService.title || "Nothing Playing"
                color: Core.Theme.foreground
                font.pixelSize: Core.UiStyle.fontTitle + 2
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                font.family: Core.Theme.fontFamily
                text: Services.MprisService.artist || "--"
                color: Core.Theme.muted
                font.pixelSize: Core.UiStyle.fontBody
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Core.UiStyle.controlHeight

            Row {
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: 40
                    Rectangle {
                        required property int index
                        width: (parent.width - 39 * 2) / 40
                        radius: Math.min(1, Core.UiStyle.radiusControl)
                        color: Core.Theme.accent
                        opacity: Services.MprisService.status === "Playing" ? barAnim.value : 0.12
                        anchors.bottom: parent.bottom
                        height: Services.MprisService.status === "Playing" ? parent.height * barAnim.value : parent.height * 0.08

                        Timer {
                            id: barAnim
                            property real value: 0.12
                            interval: 70 + index * 5
                            running: !Core.UiStyle.motionNone && Services.MprisService.status === "Playing" && panel.visible
                            repeat: true
                            triggeredOnStart: true
                            onTriggered: value = 0.12 + Math.random() * 0.88
                        }

                        Behavior on height { NumberAnimation { duration: Core.UiStyle.motionFastMs; easing.type: Easing.OutQuad } }
                        Behavior on opacity { NumberAnimation { duration: Core.UiStyle.motionFastMs } }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: Core.UiStyle.borderWidth
            color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.5)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Core.UiStyle.spacing2xl

            Text {
                font.family: Core.Theme.fontFamily
                text: "󰒮"
                color: Services.MprisService.canPrev ? Core.Theme.foreground : Core.Theme.muted
                font.pixelSize: Core.UiStyle.iconSize + 10
                MouseArea {
                    id: panelPrevArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: Services.MprisService.canPrev
                    onClicked: Services.MprisService.previous()
                }
                Components.PressBounce { pressed: panelPrevArea.pressed }
            }

            Rectangle {
                width: Core.UiStyle.controlHeightLarge
                height: Core.UiStyle.controlHeightLarge
                radius: Core.UiStyle.radiusControl
                color: Core.Theme.accent

                Text {
                    font.family: Core.Theme.fontFamily
                    anchors.centerIn: parent
                    text: Services.MprisService.status === "Playing" ? "󰏤" : "󰐊"
                    color: Core.Theme.background
                    font.pixelSize: Core.UiStyle.iconSize + 10
                }

                MouseArea {
                    id: panelPlayPauseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.MprisService.playPause()
                }
                Components.PressBounce { pressed: panelPlayPauseArea.pressed }
            }

            Text {
                font.family: Core.Theme.fontFamily
                text: "󰒭"
                color: Services.MprisService.canNext ? Core.Theme.foreground : Core.Theme.muted
                font.pixelSize: Core.UiStyle.iconSize + 10
                MouseArea {
                    id: panelNextArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: Services.MprisService.canNext
                    onClicked: Services.MprisService.next()
                }
                Components.PressBounce { pressed: panelNextArea.pressed }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Core.UiStyle.spacingSm

            Text {
                font.family: Core.Theme.fontFamily
                text: Services.AudioService.muted ? "󰝟" : "󰕾"
                color: Services.AudioService.muted ? Core.Theme.muted : Core.Theme.foreground
                font.pixelSize: Core.UiStyle.iconSize + 4
                MouseArea {
                    id: panelMuteArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.AudioService.toggleMute()
                }
                Components.PressBounce { pressed: panelMuteArea.pressed }
            }

            Rectangle {
                Layout.fillWidth: true
                height: Core.UiStyle.grid
                radius: Math.min(Core.UiStyle.radiusControl, height / 2)
                color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.42)

                Rectangle {
                    width: parent.width * Services.AudioService.volume / 100
                    height: parent.height
                    radius: parent.radius
                    color: Services.AudioService.muted ? Core.Theme.muted : Core.Theme.accent
                    Behavior on width { NumberAnimation { duration: Core.UiStyle.motionNormalMs } }
                }
            }

            Text {
                font.family: Core.Theme.fontFamily
                text: Services.AudioService.volume + "%"
                color: Core.Theme.muted
                font.pixelSize: Core.UiStyle.fontSecondary
            }
        }
    }
}
