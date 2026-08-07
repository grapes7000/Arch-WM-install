import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../components" as Components
import "../../services" as Services

Item {
    id: root

    property var context: ({
        variant: "standard",
        settings: ({}),
        locked: false,
        allows: function() { return false }
    })

    implicitWidth: pill.horizontalPadding * 2 + content.implicitWidth
    implicitHeight: pill.verticalPadding * 2 + content.implicitHeight

    Components.BarPill {
        id: pill
        anchors.fill: parent
        clickable: context.allows("drawer.open")
        onClicked: context.request("drawer.open", { kind: "calendar", anchorItem: root })
    }

    ColumnLayout {
        id: content
        anchors.centerIn: parent
        spacing: context.variant === "compact" ? 0 : 4

        Text {
            font.family: Core.Theme.fontFamily
            Layout.alignment: Qt.AlignHCenter
            text: context.variant === "compact"
                ? Services.TimeService.timeShort
                : Services.TimeService.timeLong
            color: Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 15
                : context.variant === "standard" ? 28 : 48
            font.bold: true
        }

        Text {
            font.family: Core.Theme.fontFamily
            Layout.alignment: Qt.AlignHCenter
            visible: context.variant !== "compact"
            text: context.variant === "expanded"
                ? Services.TimeService.dateLong : Services.TimeService.dateShort
            color: Core.Theme.muted
            font.pixelSize: context.variant === "expanded" ? 16 : 13
        }
    }
}

