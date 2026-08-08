import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components

Item {
    id: panel

    readonly property date today: new Date()
    readonly property date displayedMonth: new Date(today.getFullYear(), today.getMonth(), 1)
    readonly property var dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        Components.TintedCard {
            Layout.fillWidth: true
            implicitHeight: headerCol.implicitHeight + 24

            ColumnLayout {
                id: headerCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 2

                Text {
                    font.family: Core.Theme.fontFamily
                    text: Services.TimeService.timeShort
                    color: Core.Theme.foreground
                    font.pixelSize: 22
                    font.bold: true
                }

                Text {
                    font.family: Core.Theme.fontFamily
                    text: Services.TimeService.dateLong
                    color: Core.Theme.muted
                    font.pixelSize: 11
                }
            }
        }

        Components.TintedCard {
            Layout.fillWidth: true
            implicitHeight: calendarCol.implicitHeight + 24

            ColumnLayout {
                id: calendarCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                Text {
                    font.family: Core.Theme.fontFamily
                    text: panel.displayedMonth.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    color: Core.Theme.foreground
                    font.pixelSize: 13
                    font.bold: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 4
                    rowSpacing: 4

                    Repeater {
                        model: panel.dayNames
                        Text {
                            required property string modelData
                            font.family: Core.Theme.fontFamily
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
                            readonly property int day: index - panel.displayedMonth.getDay() + 1
                            readonly property int daysInMonth: new Date(
                                panel.displayedMonth.getFullYear(), panel.displayedMonth.getMonth() + 1, 0
                            ).getDate()
                            readonly property bool current: day === panel.today.getDate()
                                && panel.displayedMonth.getMonth() === panel.today.getMonth()
                                && panel.displayedMonth.getFullYear() === panel.today.getFullYear()
                            readonly property bool inMonth: day >= 1 && day <= daysInMonth

                            Layout.fillWidth: true
                            Layout.preferredHeight: 26
                            radius: Core.Theme.radius
                            color: current ? Core.Theme.accent : "transparent"
                            opacity: inMonth ? 1.0 : 0.0

                            Text {
                                font.family: Core.Theme.fontFamily
                                anchors.centerIn: parent
                                text: parent.inMonth ? parent.day : ""
                                color: parent.current ? Core.Theme.background : Core.Theme.foreground
                                font.bold: parent.current
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }
        }
    }
}
