import QtQuick
import ArchWmShell 1.0

Item {
    id: root

    required property var context

    implicitWidth: context.variant === "compact" ? 220 : 360
    implicitHeight: title.implicitHeight

    Text {
        id: title
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        text: ActiveWindowService.title
        color: Theme.foreground
        font.pixelSize: context.variant === "compact" ? 13 : 16
        font.bold: context.variant !== "compact"
        elide: Text.ElideRight
        maximumLineCount: 1
    }
}
