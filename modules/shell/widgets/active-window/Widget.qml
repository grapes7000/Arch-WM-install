import QtQuick
import "../../core" as Core
import "../../services" as Services

Item {
    id: root

    required property var context

    implicitWidth: context.variant === "compact" ? 220 : 360
    implicitHeight: title.implicitHeight

    Text {
        id: title
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        text: Services.ActiveWindowService.title
        color: Core.Theme.foreground
        font.pixelSize: context.variant === "compact" ? 13 : 16
        font.bold: context.variant !== "compact"
        elide: Text.ElideRight
        maximumLineCount: 1
    }
}
