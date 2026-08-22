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
        spacing: Core.UiStyle.spacingSm

        Components.TintedCard {
            Layout.fillWidth: true
            implicitHeight: headerCol.implicitHeight + Core.UiStyle.spacing2xl

            ColumnLayout {
                id: headerCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Core.UiStyle.spacingMd
                spacing: Core.UiStyle.spacingXs / 2

                // Deliberately high-salience: the clock remains large in every style.
                Text {
                    font.family: Core.Theme.fontFamily
                    text: Services.TimeService.timeShort
                    color: Core.Theme.foreground
                    font.pixelSize: 25
                    font.bold: true
                }

                Text {
                    font.family: Core.Theme.fontFamily
                    text: Services.TimeService.dateLong
                    color: Core.Theme.muted
                    font.pixelSize: Core.UiStyle.fontSecondary
                }
            }
        }

        Components.TintedCard {
            Layout.fillWidth: true
            implicitHeight: calendarCol.implicitHeight + Core.UiStyle.spacing2xl

            ColumnLayout {
                id: calendarCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Core.UiStyle.spacingMd
                spacing: Core.UiStyle.spacingSm

                Text {
                    font.family: Core.Theme.fontFamily
                    text: panel.displayedMonth.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    color: Core.Theme.foreground
                    font.pixelSize: Core.UiStyle.fontTitle
                    font.bold: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: Core.UiStyle.spacingXs
                    rowSpacing: Core.UiStyle.spacingXs

                    Repeater {
                        model: panel.dayNames
                        Text {
                            required property string modelData
                            font.family: Core.Theme.fontFamily
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.fontCaption
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
                            Layout.preferredHeight: Core.UiStyle.controlHeightCompact
                            radius: Core.UiStyle.radiusControl
                            color: current ? Core.Theme.accent : "transparent"
                            opacity: inMonth ? 1.0 : 0.0

                            Text {
                                font.family: Core.Theme.fontFamily
                                anchors.centerIn: parent
                                text: parent.inMonth ? parent.day : ""
                                color: parent.current ? Core.Theme.background : Core.Theme.foreground
                                font.bold: parent.current
                                font.pixelSize: Core.UiStyle.fontBody
                            }
                        }
                    }
                }
            }
        }
    }
}
