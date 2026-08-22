import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components

Item {
    id: panel

    implicitHeight: layout.implicitHeight

    readonly property var actions: [
        { label: "Lock", icon: "󰌾", action: "lock", urgent: false },
        { label: "Log out", icon: "󰍃", action: "logout", urgent: false },
        { label: "Suspend", icon: "󰤄", action: "suspend", urgent: false },
        { label: "Restart", icon: "󰜉", action: "reboot", urgent: false },
        { label: "Power off", icon: "󰐥", action: "poweroff", urgent: true }
    ]

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Core.UiStyle.spacingSm

        Text {
            font.family: Core.Theme.fontFamily
            Layout.fillWidth: true
            text: "Session"
            color: Core.Theme.foreground
            font.pixelSize: Core.UiStyle.fontTitle
            font.bold: true
        }

        Repeater {
            model: panel.actions

            Components.TintedCard {
                id: actionCard
                required property var modelData
                readonly property bool armed: Services.SessionService.pendingAction === modelData.action
                Layout.fillWidth: true
                implicitHeight: Math.max(Core.UiStyle.controlHeight, actionRow.implicitHeight + Core.UiStyle.spacingSm)
                active: armed
                tintColor: modelData.urgent ? Core.Theme.urgent : Core.Theme.accent

                RowLayout {
                    id: actionRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Core.UiStyle.spacingMd
                    spacing: Core.UiStyle.spacingSm

                    Text {
                        font.family: Core.Theme.fontFamily
                        text: actionCard.modelData.icon
                        color: actionCard.modelData.urgent ? Core.Theme.urgent : Core.Theme.foreground
                        font.pixelSize: Core.UiStyle.iconSize + 3
                    }

                    Text {
                        Layout.fillWidth: true
                        font.family: Core.Theme.fontFamily
                        text: actionCard.armed
                            ? "Confirm " + actionCard.modelData.label + "?"
                            : actionCard.modelData.label
                        color: actionCard.modelData.urgent ? Core.Theme.urgent : Core.Theme.foreground
                        font.pixelSize: Core.UiStyle.fontBody
                        font.bold: actionCard.armed
                    }
                }

                MouseArea {
                    id: actionArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.action === "lock") Services.SessionService.lock()
                        else Services.SessionService[modelData.action]()
                    }
                }
                Components.PressBounce { pressed: actionArea.pressed }
            }
        }

        Text {
            font.family: Core.Theme.fontFamily
            Layout.fillWidth: true
            visible: Services.SessionService.error !== ""
            text: Services.SessionService.error
            color: Core.Theme.urgent
            font.pixelSize: Core.UiStyle.fontBody
            wrapMode: Text.Wrap
        }
    }
}
