import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

ColumnLayout {
    implicitHeight: 380
    spacing: Core.Theme.gap

    RowLayout {
        Layout.fillWidth: true
        Text { font.family: Core.Theme.fontFamily; text: "Notifications"; color: Core.Theme.foreground; font.pixelSize: 18; font.bold: true }
        Item { Layout.fillWidth: true }
        Text { font.family: Core.Theme.fontFamily; text: Services.NotificationService.dndEnabled ? "Resume" : "Pause"; color: Core.Theme.accent; MouseArea { anchors.fill: parent; onClicked: Services.NotificationService.toggleDnd() } }
        Text { font.family: Core.Theme.fontFamily; text: "Clear"; color: Core.Theme.muted; MouseArea { anchors.fill: parent; onClicked: Services.NotificationService.dismiss() } }
    }

    Text { font.family: Core.Theme.fontFamily; visible: Services.NotificationService.recent.length === 0; text: "No recent notifications"; color: Core.Theme.muted; Layout.alignment: Qt.AlignHCenter }
    Repeater {
        model: Services.NotificationService.recent
        Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: notice.implicitHeight + Core.Theme.gap * 2
            radius: Core.Theme.radius
            color: Core.Theme.background
            ColumnLayout {
                id: notice
                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: Core.Theme.gap
                spacing: 2
                Text { font.family: Core.Theme.fontFamily; Layout.fillWidth: true; text: modelData.appName || modelData.app || "Notification"; color: Core.Theme.accent; font.pixelSize: 10; font.bold: true; elide: Text.ElideRight }
                Text { font.family: Core.Theme.fontFamily; Layout.fillWidth: true; text: modelData.summary || modelData.title || ""; color: Core.Theme.foreground; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight }
                Text { font.family: Core.Theme.fontFamily; Layout.fillWidth: true; text: modelData.body || ""; color: Core.Theme.muted; font.pixelSize: 10; maximumLineCount: 2; elide: Text.ElideRight; wrapMode: Text.Wrap }
            }
        }
    }
}

