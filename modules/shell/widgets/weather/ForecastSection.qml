import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components

Item {
    id: root

    // compact: tighter spacing/fonts for small cards.
    // expand:  fill the available height (homepage card). When false the
    //          component sizes itself from its content (drawer panel).
    property bool compact: false
    property bool expand: false
    property int selectedTab: 0   // 0 = daily, 1 = 10-day

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: root.expand ? parent.bottom : undefined
        spacing: root.compact ? 5 : 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            TabPill {
                label: "Daily"
                active: root.selectedTab === 0
                onTapped: root.selectedTab = 0
            }
            TabPill {
                label: "10 Day"
                active: root.selectedTab === 1
                onTapped: root.selectedTab = 1
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: Services.WeatherService.available
                text: "Updated " + Services.WeatherService.lastUpdated
                color: Core.Theme.muted
                font.pixelSize: root.compact ? 10 : 11
            }
        }

        Text {
            visible: !Services.WeatherService.available
                || (root.selectedTab === 1 && Services.WeatherService.daily.length === 0)
            Layout.alignment: Qt.AlignHCenter
            text: "Forecast unavailable"
            color: Core.Theme.muted
            font.pixelSize: root.compact ? 11 : 12
        }

        // ---------- Daily view ----------
        ColumnLayout {
            visible: root.selectedTab === 0 && Services.WeatherService.available
            Layout.fillWidth: true
            spacing: root.compact ? 4 : 6

            Text {
                text: "Today's Hourly"
                color: Core.Theme.muted
                font.pixelSize: root.compact ? 11 : 12
                font.bold: true
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: root.compact ? 42 : 52
                orientation: ListView.Horizontal
                spacing: root.compact ? 3 : 5
                clip: true
                interactive: true
                model: Services.WeatherService.hourly

                delegate: Column {
                    required property var modelData
                    width: root.compact ? 34 : 42
                    spacing: root.compact ? 1 : 2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.time
                        color: Core.Theme.muted
                        font.pixelSize: root.compact ? 10 : 11
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.icon
                        color: Core.Theme.foreground
                        font.pixelSize: root.compact ? 15 : 17
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.temp
                        color: Core.Theme.foreground
                        font.pixelSize: root.compact ? 11 : 13
                        font.bold: true
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: root.compact ? 3 : 4

                StatChip { label: "High"; value: Services.WeatherService.high }
                StatChip { label: "Low"; value: Services.WeatherService.low }
                StatChip { label: "Feels"; value: Services.WeatherService.feelsLike }
                StatChip { label: "Humidity"; value: Services.WeatherService.humidity }
                StatChip { label: "Wind"; value: Services.WeatherService.wind }
                StatChip { label: "Sunrise"; value: Services.WeatherService.sunrise }
                StatChip { label: "Sunset"; value: Services.WeatherService.sunset }
            }
        }

        // ---------- 10-day view ----------
        ListView {
            visible: root.selectedTab === 1 && Services.WeatherService.available
            Layout.fillWidth: true
            Layout.fillHeight: root.expand
            Layout.preferredHeight: Math.min(Services.WeatherService.daily.length, 10)
                * (root.compact ? 20 : 24)
            clip: true
            interactive: true
            model: Services.WeatherService.daily

            delegate: RowLayout {
                required property var modelData
                height: root.compact ? 20 : 24
                spacing: root.compact ? 4 : 6

                Text {
                    text: modelData.day
                    color: Core.Theme.foreground
                    font.pixelSize: root.compact ? 11 : 12
                    font.bold: true
                    Layout.preferredWidth: root.compact ? 30 : 42
                }
                Text {
                    text: modelData.icon
                    color: Core.Theme.foreground
                    font.pixelSize: root.compact ? 14 : 16
                }
                Text {
                    text: modelData.condition
                    color: Core.Theme.muted
                    font.pixelSize: root.compact ? 11 : 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: modelData.low + " / " + modelData.high
                    color: Core.Theme.foreground
                    font.pixelSize: root.compact ? 11 : 12
                    font.bold: true
                }
            }
        }
    }

    component TabPill: Rectangle {
        property string label: ""
        property bool active: false
        signal tapped()
        Layout.preferredWidth: root.compact ? 42 : 52
        Layout.preferredHeight: root.compact ? 18 : 22
        radius: height / 2
        color: active ? Core.Theme.accent : Core.Theme.surface
        border.width: 1
        border.color: active ? Core.Theme.accent : Core.Theme.accent2
        Text {
            anchors.centerIn: parent
            text: label
            color: active ? Core.Theme.background : Core.Theme.foreground
            font.pixelSize: root.compact ? 11 : 12
            font.bold: active
        }
        MouseArea {
            id: tabPillArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tapped()
        }
        Components.PressBounce { pressed: tabPillArea.pressed }
    }

    component StatChip: Rectangle {
        property string label: ""
        property string value: "--"
        implicitWidth: root.compact ? 50 : 60
        implicitHeight: root.compact ? 22 : 26
        radius: 5
        color: Core.Theme.surface
        border.width: 1
        border.color: Core.Theme.accent2
        Column {
            anchors.centerIn: parent
            spacing: 1
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: label
                color: Core.Theme.muted
                font.pixelSize: root.compact ? 9 : 10
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: value
                color: Core.Theme.foreground
                font.pixelSize: root.compact ? 11 : 12
                font.bold: true
            }
        }
    }
}
