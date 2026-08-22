import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components

Item {
    id: root

    property bool compact: false
    property bool expand: false
    property int selectedTab: 0

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: root.expand ? parent.bottom : undefined
        spacing: root.compact ? Core.UiStyle.spacingXs : Core.UiStyle.spacingSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Core.UiStyle.spacingXs

            TabControl {
                label: "Daily"
                active: root.selectedTab === 0
                onTapped: root.selectedTab = 0
            }
            TabControl {
                label: "10 Day"
                active: root.selectedTab === 1
                onTapped: root.selectedTab = 1
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: Services.WeatherService.available
                text: "Updated " + Services.WeatherService.lastUpdated
                color: Core.Theme.muted
                font.pixelSize: root.compact ? Core.UiStyle.fontCaption : Core.UiStyle.fontSecondary
            }
        }

        Text {
            visible: !Services.WeatherService.available
                || (root.selectedTab === 1 && Services.WeatherService.daily.length === 0)
            Layout.alignment: Qt.AlignHCenter
            text: "Forecast unavailable"
            color: Core.Theme.muted
            font.pixelSize: Core.UiStyle.fontSecondary
        }

        ColumnLayout {
            visible: root.selectedTab === 0 && Services.WeatherService.available
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.compact ? Core.UiStyle.spacingXs : Core.UiStyle.spacingSm

            Text {
                text: "Today's Hourly"
                color: Core.Theme.muted
                font.pixelSize: Core.UiStyle.fontSecondary
                font.bold: true
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: root.compact
                    ? Core.UiStyle.controlHeightLarge + Core.UiStyle.spacingLg
                    : Core.UiStyle.controlHeightLarge + Core.UiStyle.spacing2xl
                orientation: ListView.Horizontal
                spacing: root.compact ? Core.UiStyle.spacingXs : Core.UiStyle.spacingSm
                clip: true
                interactive: true
                model: Services.WeatherService.hourly

                delegate: Column {
                    required property var modelData
                    width: root.compact ? Core.UiStyle.controlHeightLarge : Core.UiStyle.controlHeightLarge + Core.UiStyle.spacingSm
                    spacing: Core.UiStyle.spacingXs / 2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.time
                        color: Core.Theme.muted
                        font.pixelSize: Core.UiStyle.fontCaption
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.icon
                        color: Core.Theme.foreground
                        font.pixelSize: Core.UiStyle.iconSize + (root.compact ? 1 : 3)
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.temp
                        color: Core.Theme.foreground
                        font.pixelSize: Core.UiStyle.fontBody
                        font.bold: true
                    }
                }
            }

            Item { Layout.fillHeight: true }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: root.compact ? Core.UiStyle.spacingXs : Core.UiStyle.spacingSm
                columnSpacing: root.compact ? Core.UiStyle.spacingXs : Core.UiStyle.spacingSm

                StatChip { label: "High"; value: Services.WeatherService.high; Layout.fillWidth: true }
                StatChip { label: "Low"; value: Services.WeatherService.low; Layout.fillWidth: true }
                StatChip { label: "Feels"; value: Services.WeatherService.feelsLike; Layout.fillWidth: true }
                StatChip { label: "Humidity"; value: Services.WeatherService.humidity; Layout.fillWidth: true }
                StatChip { label: "Wind"; value: Services.WeatherService.wind; Layout.fillWidth: true }
                StatChip { label: "Sunrise"; value: Services.WeatherService.sunrise; Layout.fillWidth: true }
                StatChip { label: "Sunset"; value: Services.WeatherService.sunset; Layout.fillWidth: true }
            }
        }

        ListView {
            visible: root.selectedTab === 1 && Services.WeatherService.available
            Layout.fillWidth: true
            Layout.fillHeight: root.expand
            Layout.preferredHeight: Math.min(Services.WeatherService.daily.length, 10)
                * Core.UiStyle.controlHeightCompact
            clip: true
            interactive: true
            model: Services.WeatherService.daily

            delegate: RowLayout {
                required property var modelData
                height: Core.UiStyle.controlHeightCompact
                spacing: Core.UiStyle.spacingSm

                Text {
                    text: modelData.day
                    color: Core.Theme.foreground
                    font.pixelSize: Core.UiStyle.fontSecondary
                    font.bold: true
                    Layout.preferredWidth: root.compact
                        ? Core.UiStyle.controlHeight
                        : Core.UiStyle.controlHeightLarge + Core.UiStyle.spacingSm
                }
                Text {
                    text: modelData.icon
                    color: Core.Theme.foreground
                    font.pixelSize: Core.UiStyle.iconSize
                }
                Text {
                    text: modelData.condition
                    color: Core.Theme.muted
                    font.pixelSize: Core.UiStyle.fontSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: modelData.low + " / " + modelData.high
                    color: Core.Theme.foreground
                    font.pixelSize: Core.UiStyle.fontSecondary
                    font.bold: true
                }
            }
        }
    }

    component TabControl: Rectangle {
        property string label: ""
        property bool active: false
        signal tapped()

        Layout.preferredWidth: root.compact
            ? Core.UiStyle.controlHeightLarge
            : Core.UiStyle.controlHeightLarge + Core.UiStyle.spacingLg
        Layout.preferredHeight: Core.UiStyle.controlHeightCompact
        radius: Core.UiStyle.patterns.button === "filled" ? height / 2 : Core.UiStyle.radiusControl
        color: active
            ? Core.Theme.alphaColor(Core.Theme.accent, Core.UiStyle.flatSurfaces ? 0.16 : 1.0)
            : Core.Theme.alphaColor(Core.Theme.surfaceHover, Core.UiStyle.flatSurfaces ? 0.20 : 0.62)
        border.width: Core.UiStyle.borderWidth
        border.color: active
            ? Core.Theme.accent
            : (Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor)

        Text {
            anchors.centerIn: parent
            text: label
            color: active && !Core.UiStyle.flatSurfaces ? Core.Theme.background : (active ? Core.Theme.accent : Core.Theme.foreground)
            font.pixelSize: Core.UiStyle.fontSecondary
            font.bold: active
        }
        MouseArea {
            id: tabArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tapped()
        }
        Components.PressBounce { pressed: tabArea.pressed }
    }

    component StatChip: Rectangle {
        property string label: ""
        property string value: "--"

        implicitWidth: root.compact
            ? Core.UiStyle.controlHeightLarge + Core.UiStyle.spacingMd
            : Core.UiStyle.controlHeightLarge + Core.UiStyle.spacing2xl
        implicitHeight: root.compact ? Core.UiStyle.controlHeight : Core.UiStyle.controlHeightLarge
        radius: Core.UiStyle.radiusSurface
        color: Core.Theme.alphaColor(Core.Theme.surfaceHover, Core.UiStyle.flatSurfaces ? 0.24 : 0.62)
        border.width: Core.UiStyle.borderWidth
        border.color: Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor

        Column {
            anchors.centerIn: parent
            spacing: Core.UiStyle.spacingXs / 2
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: label
                color: Core.Theme.muted
                font.pixelSize: Core.UiStyle.fontCaption
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: value
                color: Core.Theme.foreground
                font.pixelSize: Core.UiStyle.fontSecondary
                font.bold: true
            }
        }
    }
}
