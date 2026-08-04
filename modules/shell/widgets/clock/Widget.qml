import QtQuick
import "../.."

Item {
    id: root

    required property var context
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Text {
        id: label
        text: context.variant === "compact"
            ? Qt.formatTime(root.now, "hh:mm")
            : Qt.formatDateTime(root.now, "dddd, MMMM d  hh:mm")
        color: Theme.roles.text || "#ffffff"
        font.pixelSize: context.variant === "compact" ? 15 : 22
        font.bold: context.variant === "compact"
    }
}
