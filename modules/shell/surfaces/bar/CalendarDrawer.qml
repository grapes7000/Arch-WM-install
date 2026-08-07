import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

ColumnLayout {
    id: root
    implicitHeight: 330
    spacing: Core.Theme.gap

    readonly property date today: new Date()
    property date displayedMonth: new Date(today.getFullYear(), today.getMonth(), 1)
    readonly property var dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    RowLayout {
        Layout.fillWidth: true
        Text { font.family: Core.Theme.fontFamily; text: "Calendar"; color: Core.Theme.foreground; font.pixelSize: 18; font.bold: true }
        Item { Layout.fillWidth: true }
        Text { font.family: Core.Theme.fontFamily; text: Services.TimeService.timeLong; color: Core.Theme.accent; font.pixelSize: 16; font.bold: true }
    }

    Text {
        font.family: Core.Theme.fontFamily
        text: displayedMonth.toLocaleDateString(Qt.locale(), "MMMM yyyy")
        color: Core.Theme.foreground
        font.pixelSize: 15
        font.bold: true
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        columnSpacing: Core.Theme.gap / 2
        rowSpacing: Core.Theme.gap / 2

        Repeater {
            model: root.dayNames
            Text {
                font.family: Core.Theme.fontFamily
                required property string modelData
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Core.Theme.muted
                font.pixelSize: 10
            }
        }

        Repeater {
            model: 42
            Rectangle {
                required property int index
                readonly property int day: index - root.displayedMonth.getDay() + 1
                readonly property int daysInMonth: new Date(
                    root.displayedMonth.getFullYear(), root.displayedMonth.getMonth() + 1, 0
                ).getDate()
                readonly property bool current: day === root.today.getDate()
                    && root.displayedMonth.getMonth() === root.today.getMonth()
                    && root.displayedMonth.getFullYear() === root.today.getFullYear()
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: Core.Theme.radius
                color: current ? Core.Theme.accent2 : "transparent"
                Text {
                    font.family: Core.Theme.fontFamily
                    anchors.centerIn: parent
                    text: parent.day >= 1 && parent.day <= parent.daysInMonth ? parent.day : ""
                    color: parent.current ? Core.Theme.foreground : Core.Theme.muted
                    font.bold: parent.current
                    font.pixelSize: 11
                }
            }
        }
    }
}

