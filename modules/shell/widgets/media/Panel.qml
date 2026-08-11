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
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                font.family: Core.Theme.fontFamily
                text: Services.MprisService.title || "Nothing Playing"
                color: Core.Theme.foreground
                font.pixelSize: 19
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                font.family: Core.Theme.fontFamily
                text: Services.MprisService.artist || "--"
                color: Core.Theme.muted
                font.pixelSize: 15
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            Row {
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: 40
                    Rectangle {
                        required property int index
                        width: (parent.width - 39 * 2) / 40
                        radius: 1
                        color: Core.Theme.accent
                        opacity: Services.MprisService.status === "Playing"
                            ? barAnim.value : 0.12
                        anchors.bottom: parent.bottom

                        height: Services.MprisService.status === "Playing"
                            ? parent.height * barAnim.value
                            : parent.height * 0.08

                        Timer {
                            id: barAnim
                            property real value: 0.12
                            interval: 70 + index * 5
                            running: Services.MprisService.status === "Playing" && panel.visible
                            repeat: true
                            triggeredOnStart: true
                            onTriggered: value = 0.12 + Math.random() * 0.88
                        }

                        Behavior on height {
                            NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 120 }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Core.Theme.muted
            opacity: 0.2
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 24

            Text {
                font.family: Core.Theme.fontFamily
                text: "󰒮"
                color: Services.MprisService.canPrev ? Core.Theme.foreground : Core.Theme.muted
                font.pixelSize: 25
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
                width: 44; height: 44
                radius: 22
                color: Core.Theme.accent

                Text {
                    font.family: Core.Theme.fontFamily
                    anchors.centerIn: parent
                    text: Services.MprisService.status === "Playing" ? "󰏤" : "󰐊"
                    color: Core.Theme.surface
                    font.pixelSize: 27
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
                font.pixelSize: 25
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
            spacing: 8

            Text {
                font.family: Core.Theme.fontFamily
                text: Services.AudioService.muted ? "󰝟" : "󰕾"
                color: Services.AudioService.muted ? Core.Theme.muted : Core.Theme.foreground
                font.pixelSize: 19
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
                height: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.1)

                Rectangle {
                    width: parent.width * Services.AudioService.volume / 100
                    height: parent.height
                    radius: parent.radius
                    color: Services.AudioService.muted ? Core.Theme.muted : Core.Theme.accent
                    Behavior on width { NumberAnimation { duration: 200 } }
                }
            }

            Text {
                font.family: Core.Theme.fontFamily
                text: Services.AudioService.volume + "%"
                color: Core.Theme.muted
                font.pixelSize: 14
            }
        }
    }
}

