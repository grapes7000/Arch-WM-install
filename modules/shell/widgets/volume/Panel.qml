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
        spacing: 10

        Components.TintedCard {
            visible: Services.AudioService.error === ""
            Layout.fillWidth: true
            implicitHeight: mainCol.implicitHeight + 24

            ColumnLayout {
                id: mainCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    spacing: 12

                    Text {
                        font.family: Core.Theme.fontFamily
                        text: Services.AudioService.muted ? "󰝟"
                            : Services.AudioService.volume >= 66 ? "󰕾"
                            : Services.AudioService.volume >= 33 ? "󰖀" : "󰕿"
                        color: Services.AudioService.muted ? Core.Theme.muted : Core.Theme.accent
                        font.pixelSize: 25

                        MouseArea {
                            id: muteArea
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.AudioService.toggleMute()
                        }
                        Components.PressBounce { pressed: muteArea.pressed }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: "Volume"
                            color: Core.Theme.foreground
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: Services.AudioService.muted
                                ? "Muted"
                                : (Services.MprisService.status === "Playing"
                                    ? (Services.MprisService.title || "Playing")
                                    : "System volume")
                            color: Core.Theme.muted
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                    }

                    Components.StatusPill {
                        visible: Services.AudioService.muted
                        active: Services.AudioService.muted
                        activeLabel: "MUTED"
                        pulse: false
                    }

                    Text {
                        font.family: Core.Theme.fontFamily
                        text: Services.AudioService.volume + "%"
                        color: Core.Theme.foreground
                        font.pixelSize: 16
                        font.bold: true
                    }
                }

                Rectangle {
                    id: sliderTrack
                    Layout.fillWidth: true
                    height: 10
                    radius: 5
                    color: Qt.rgba(Qt.color(Core.Theme.foreground).r,
                        Qt.color(Core.Theme.foreground).g,
                        Qt.color(Core.Theme.foreground).b, 0.08)

                    Rectangle {
                        width: sliderTrack.width * (Services.AudioService.muted ? 0 : Services.AudioService.volume / 100)
                        height: parent.height
                        radius: parent.radius
                        color: Services.AudioService.muted ? Core.Theme.muted : Core.Theme.accent

                        Behavior on width {
                            enabled: !sliderArea.dragging
                            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                        }
                    }

                    MouseArea {
                        id: sliderArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        property bool dragging: false

                        function updateFromX(x) {
                            const pct = Math.max(0, Math.min(100, Math.round(x / sliderTrack.width * 100)))
                            Services.AudioService.setVolume(pct)
                        }

                        onPressed: mouse => { dragging = true; updateFromX(mouse.x) }
                        onPositionChanged: mouse => { if (dragging) updateFromX(mouse.x) }
                        onReleased: dragging = false
                    }
                }

                Row {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    visible: Services.MprisService.status === "Playing"
                    spacing: 2

                    Repeater {
                        model: Services.CavaService.bars
                        Rectangle {
                            required property real modelData
                            required property int index
                            width: Math.max(2, (parent.width - (Services.CavaService.bars.length - 1) * parent.spacing) / Math.max(1, Services.CavaService.bars.length))
                            height: Math.max(3, parent.height * modelData)
                            anchors.bottom: parent.bottom
                            radius: width / 2
                            color: index % 2 ? Core.Theme.accent2 : Core.Theme.accent
                            Behavior on height { NumberAnimation { duration: 70 } }
                        }
                    }
                }
            }
        }

        Components.EmptyState {
            visible: Services.AudioService.error !== ""
            Layout.fillWidth: true
            icon: "󰎊"
            message: "No audio devices"
        }
    }
}
