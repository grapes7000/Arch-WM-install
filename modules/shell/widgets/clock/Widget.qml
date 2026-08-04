import QtQuick
import QtQuick.Layouts
import ArchWmShell 1.0

Item {
    id: root

    required property var context

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    ColumnLayout {
        id: content
        anchors.centerIn: parent
        spacing: context.variant === "compact" ? 0 : 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: context.variant === "compact"
                ? TimeService.timeShort
                : TimeService.timeLong
            color: Theme.foreground
            font.pixelSize: context.variant === "compact" ? 15
                : context.variant === "standard" ? 28 : 48
            font.bold: true
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: context.variant !== "compact"
            text: context.variant === "expanded"
                ? TimeService.dateLong : TimeService.dateShort
            color: Theme.muted
            font.pixelSize: context.variant === "expanded" ? 16 : 13
        }
    }
}
