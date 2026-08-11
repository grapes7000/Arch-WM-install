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
            Layout.fillWidth: true
            implicitHeight: headerCol.implicitHeight + 24

            ColumnLayout {
                id: headerCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    spacing: 12

                    Text {
                        font.family: Core.Theme.fontFamily
                        text: "󰂚"
                        color: Core.Theme.accent
                        font.pixelSize: 25
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: "Notifications"
                            color: Core.Theme.foreground
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: Services.NotificationService.count
                                + (Services.NotificationService.count === 1 ? " notification" : " notifications")
                            color: Core.Theme.muted
                            font.pixelSize: 13
                        }
                    }

                    Components.StatusPill {
                        visible: Services.NotificationService.dndEnabled
                        active: Services.NotificationService.dndEnabled
                        activeLabel: "DND"
                        pulse: false
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Text {
                        font.family: Core.Theme.fontFamily
                        text: Services.NotificationService.dndEnabled ? "Resume notifications" : "Pause (DND)"
                        color: Core.Theme.accent
                        font.pixelSize: 14
                        font.bold: true

                        MouseArea {
                            id: dndArea
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.NotificationService.toggleDnd()
                        }
                        Components.PressBounce { pressed: dndArea.pressed }
                    }

                    Text {
                        font.family: Core.Theme.fontFamily
                        visible: Services.NotificationService.recent.length > 0
                        text: "Dismiss all"
                        color: Core.Theme.muted
                        font.pixelSize: 14

                        MouseArea {
                            id: dismissArea
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.NotificationService.dismiss()
                        }
                        Components.PressBounce { pressed: dismissArea.pressed }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: Services.NotificationService.recent.length > 0

            Repeater {
                model: Services.NotificationService.recent

                Components.TintedCard {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: noticeCol.implicitHeight + 20

                    ColumnLayout {
                        id: noticeCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 2

                        Text {
                            font.family: Core.Theme.fontFamily
                            Layout.fillWidth: true
                            text: modelData.appName || "Notification"
                            color: Core.Theme.accent
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            font.family: Core.Theme.fontFamily
                            Layout.fillWidth: true
                            text: modelData.summary || ""
                            color: Core.Theme.foreground
                            font.pixelSize: 15
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            font.family: Core.Theme.fontFamily
                            Layout.fillWidth: true
                            visible: modelData.body !== ""
                            text: modelData.body || ""
                            color: Core.Theme.muted
                            font.pixelSize: 13
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }

        Components.EmptyState {
            visible: Services.NotificationService.recent.length === 0
            Layout.fillWidth: true
            icon: "󰂛"
            message: "No notifications"
        }
    }
}
