import QtQuick
import "../../core" as Core
import "../../services" as Services

Item {
    id: root

    property var context: ({
        variant: "standard",
        settings: ({}),
        locked: false,
        allows: function() { return false }
    })

    implicitWidth: context.variant === "compact" ? 170 : 320
    implicitHeight: title.implicitHeight

    Text {
        font.family: Core.Theme.fontFamily
        id: title
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        text: Services.ActiveWindowService.title || "Desktop"
        color: Services.ActiveWindowService.title ? Core.Theme.foreground : Core.Theme.muted
        font.pixelSize: context.variant === "compact" ? 12 : 16
        font.bold: context.variant !== "compact"
        elide: Text.ElideRight
        maximumLineCount: 1
    }
}

