import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

ColumnLayout {
    implicitHeight: 270
    spacing: Core.Theme.gap

    Text { font.family: Core.Theme.fontFamily; text: "Session"; color: Core.Theme.foreground; font.pixelSize: 18; font.bold: true }
    Text { font.family: Core.Theme.fontFamily; text: "Destructive actions require a second click."; color: Core.Theme.muted; font.pixelSize: 10 }

    Repeater {
        model: [
            { label: "Lock", action: "lock", urgent: false },
            { label: "Log out", action: "logout", urgent: false },
            { label: "Suspend", action: "suspend", urgent: false },
            { label: "Restart", action: "reboot", urgent: true },
            { label: "Power off", action: "poweroff", urgent: true }
        ]
        Rectangle {
            required property var modelData
            Layout.fillWidth: true
            height: 34
            radius: Core.Theme.radius
            color: Services.SessionService.pendingAction === modelData.action ? Core.Theme.accent2 : Core.Theme.background
            Text {
                font.family: Core.Theme.fontFamily
                anchors.centerIn: parent
                text: Services.SessionService.pendingAction === parent.modelData.action ? "Confirm " + parent.modelData.label : parent.modelData.label
                color: parent.modelData.urgent ? Core.Theme.urgent : Core.Theme.foreground
                font.bold: Services.SessionService.pendingAction === parent.modelData.action
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (modelData.action === "lock") Services.SessionService.lock()
                    else Services.SessionService[modelData.action]()
                }
            }
        }
    }
    Text { font.family: Core.Theme.fontFamily; visible: Services.SessionService.error !== ""; text: Services.SessionService.error; color: Core.Theme.urgent; font.pixelSize: 10; Layout.fillWidth: true; wrapMode: Text.Wrap }
}

