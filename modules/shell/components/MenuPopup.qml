import QtQuick
import QtQuick.Layouts
import Quickshell
import "../core" as Core
import "../services" as Services

PanelWindow {
    id: popup

    property bool menuOpen: false
    property string currentWidget: ""
    property string currentWidgetName: ""

    visible: menuOpen
    screen: Quickshell.screens[0]

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    focusable: true
    color: "transparent"

    function close() {
        menuOpen = false
        currentWidget = ""
        currentWidgetName = ""
    }

    function toggle() {
        if (menuOpen) {
            close()
        } else {
            menuOpen = true
        }
    }

    function openTo(kind) {
        const definition = Core.WidgetRegistry.definition(kind)
        menuOpen = true
        currentWidget = kind
        currentWidgetName = definition ? definition.name : kind
    }

    MouseArea {
        id: backdrop
        anchors.fill: parent
        onClicked: popup.close()
    }

    Item {
        id: escapeDismissal
        anchors.fill: parent
        focus: popup.menuOpen

        Keys.onEscapePressed: popup.close()
    }

    Rectangle {
        id: card
        anchors {
            top: parent.top
            right: parent.right
        }
        anchors.topMargin: Core.Theme.barHeight + Core.Theme.gap * 3
        anchors.rightMargin: Core.Theme.gap
        width: 340
        implicitHeight: mainCol.implicitHeight + 24
        color: Core.Theme.surface
        radius: Core.Theme.radius
        border.width: Core.Theme.borderWidth
        border.color: Core.Theme.accent2

        MouseArea {
            id: cardClickShield
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: mainCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: popup.currentWidget !== ""

                Text {
                    font.family: Core.Theme.fontFamily
                    text: "←"
                    color: Core.Theme.foreground
                    font.pixelSize: 19
                    MouseArea {
                        id: backArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.currentWidget = ""
                            popup.currentWidgetName = ""
                        }
                    }
                    PressBounce { pressed: backArea.pressed }
                }

                Text {
                    font.family: Core.Theme.fontFamily
                    text: popup.currentWidgetName
                    color: Core.Theme.foreground
                    font.pixelSize: 17
                    font.bold: true
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: overviewCol.implicitHeight
                visible: popup.currentWidget === ""

                ColumnLayout {
                    id: overviewCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                font.family: Core.Theme.fontFamily
                                text: Services.TimeService.timeLong
                                color: Core.Theme.foreground
                                font.pixelSize: 31
                                font.bold: true
                            }

                            Text {
                                font.family: Core.Theme.fontFamily
                                text: Services.TimeService.dateLong
                                color: Core.Theme.muted
                                font.pixelSize: 14
                            }
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 12

                            ColumnLayout {
                                spacing: 0

                                Text {
                                    font.family: Core.Theme.fontFamily
                                    text: {
                                        if (!Services.PowerService.available) return "󰁹"
                                        if (Services.PowerService.charging) return "󰂄"
                                        const p = Services.PowerService.percent
                                        if (p >= 90) return "󰁹"
                                        if (p >= 70) return "󰂁"
                                        if (p >= 50) return "󰁾"
                                        if (p >= 30) return "󰁼"
                                        if (p >= 10) return "󰁺"
                                        return "󰂃"
                                    }
                                    color: {
                                        if (!Services.PowerService.available) return Core.Theme.muted
                                        if (Services.PowerService.percent <= 15 && !Services.PowerService.charging)
                                            return Core.Theme.urgent
                                        return Core.Theme.foreground
                                    }
                                    font.pixelSize: 21
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    font.family: Core.Theme.fontFamily
                                    text: Services.PowerService.available
                                        ? Services.PowerService.percent + "%" : "--"
                                    color: Core.Theme.muted
                                    font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            ColumnLayout {
                                spacing: 0

                                Text {
                                    font.family: Core.Theme.fontFamily
                                    text: {
                                        if (Services.NotificationService.dndEnabled) return "󰂛"
                                        if (Services.NotificationService.count > 0) return "󰂚"
                                        return "󰂜"
                                    }
                                    color: Services.NotificationService.count > 0
                                        ? Core.Theme.accent : Core.Theme.muted
                                    font.pixelSize: 21
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    font.family: Core.Theme.fontFamily
                                    text: Services.NotificationService.count > 0
                                        ? Services.NotificationService.count : ""
                                    color: Core.Theme.muted
                                    font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: Math.max(6, Core.Theme.radius - 2)
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)

                        MouseArea {
                            id: systemStatsArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.currentWidget = "system-stats"
                                popup.currentWidgetName = "System"
                            }
                        }
                        PressBounce { pressed: systemStatsArea.pressed }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 16

                            RowLayout {
                                spacing: 4
                                Text { font.family: Core.Theme.fontFamily; text: "CPU"; color: Core.Theme.muted; font.pixelSize: 13 }
                                Text {
                                    font.family: Core.Theme.fontFamily
                                    text: Services.SystemStatsService.cpuPercent + "%"
                                    color: Services.SystemStatsService.cpuPercent >= 90
                                        ? Core.Theme.urgent : Core.Theme.foreground
                                    font.pixelSize: 15; font.bold: true
                                }
                            }

                            RowLayout {
                                spacing: 4
                                Text { font.family: Core.Theme.fontFamily; text: "RAM"; color: Core.Theme.muted; font.pixelSize: 13 }
                                Text {
                                    font.family: Core.Theme.fontFamily
                                    text: Services.SystemStatsService.memoryPercent + "%"
                                    color: Services.SystemStatsService.memoryPercent >= 90
                                        ? Core.Theme.urgent : Core.Theme.foreground
                                    font.pixelSize: 15; font.bold: true
                                }
                            }

                            RowLayout {
                                spacing: 4
                                Text { font.family: Core.Theme.fontFamily; text: "DISK"; color: Core.Theme.muted; font.pixelSize: 13 }
                                Text {
                                    font.family: Core.Theme.fontFamily
                                    text: Services.SystemStatsService.diskPercent + "%"
                                    color: Services.SystemStatsService.diskPercent >= 90
                                        ? Core.Theme.urgent : Core.Theme.foreground
                                    font.pixelSize: 15; font.bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                font.family: Core.Theme.fontFamily
                                text: "›"
                                color: Core.Theme.muted
                                font.pixelSize: 17
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: mediaCol.implicitHeight + 20
                        radius: Math.max(6, Core.Theme.radius - 2)
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)
                        visible: Services.MprisService.status !== "Stopped"

                        MouseArea {
                            id: mediaCardArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.currentWidget = "media"
                                popup.currentWidgetName = "Now Playing"
                            }
                        }
                        PressBounce { pressed: mediaCardArea.pressed }

                        ColumnLayout {
                            id: mediaCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: 8

                            Text {
                                font.family: Core.Theme.fontFamily
                                text: "NOW PLAYING"
                                color: Core.Theme.accent
                                font.pixelSize: 12
                                font.bold: true
                                font.letterSpacing: 1
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        font.family: Core.Theme.fontFamily
                                        text: Services.MprisService.title || "Unknown"
                                        color: Core.Theme.foreground
                                        font.pixelSize: 16
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        font.family: Core.Theme.fontFamily
                                        text: Services.MprisService.artist || "Unknown Artist"
                                        color: Core.Theme.muted
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                RowLayout {
                                    spacing: 8

                                    Text {
                                        font.family: Core.Theme.fontFamily
                                        text: "󰒮"
                                        color: Core.Theme.foreground
                                        font.pixelSize: 19
                                        visible: Services.MprisService.canPrev
                                        MouseArea {
                                            id: mpPrevArea
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Services.MprisService.previous()
                                        }
                                        PressBounce { pressed: mpPrevArea.pressed }
                                    }

                                    Text {
                                        font.family: Core.Theme.fontFamily
                                        text: Services.MprisService.status === "Playing" ? "󰏤" : "󰐊"
                                        color: Core.Theme.accent
                                        font.pixelSize: 23
                                        MouseArea {
                                            id: mpPlayPauseArea
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Services.MprisService.playPause()
                                        }
                                        PressBounce { pressed: mpPlayPauseArea.pressed }
                                    }

                                    Text {
                                        font.family: Core.Theme.fontFamily
                                        text: "󰒭"
                                        color: Core.Theme.foreground
                                        font.pixelSize: 19
                                        visible: Services.MprisService.canNext
                                        MouseArea {
                                            id: mpNextArea
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Services.MprisService.next()
                                        }
                                        PressBounce { pressed: mpNextArea.pressed }
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24

                                Row {
                                    anchors.fill: parent
                                    anchors.topMargin: 4
                                    spacing: 2

                                    Repeater {
                                        model: 32
                                        Rectangle {
                                            required property int index
                                            width: (parent.width - 31 * 2) / 32
                                            radius: 1
                                            color: Core.Theme.accent
                                            opacity: Services.MprisService.status === "Playing"
                                                ? barAnim.value : 0.15
                                            anchors.bottom: parent.bottom

                                            property real seed: Math.random()

                                            height: Services.MprisService.status === "Playing"
                                                ? parent.height * barAnim.value
                                                : parent.height * 0.1

                                            NumberAnimation on height {
                                                id: barHeightAnim
                                                running: false
                                            }

                                            Timer {
                                                id: barAnim
                                                property real value: 0.15
                                                interval: 80 + index * 7
                                                running: Services.MprisService.status === "Playing" && popup.menuOpen
                                                repeat: true
                                                triggeredOnStart: true
                                                onTriggered: {
                                                    value = 0.15 + Math.random() * 0.85
                                                }
                                            }

                                            Behavior on height {
                                                NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                                            }

                                            Behavior on opacity {
                                                NumberAnimation { duration: 150 }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: !Services.MprisService.status !== "Stopped"
                            ? false : true
                        implicitHeight: 0
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: weatherRow.implicitHeight + 20
                        radius: Math.max(6, Core.Theme.radius - 2)
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)
                        visible: Services.WeatherService.available

                        MouseArea {
                            id: weatherCardArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.currentWidget = "weather"
                                popup.currentWidgetName = "Weather"
                            }
                        }
                        PressBounce { pressed: weatherCardArea.pressed }

                        RowLayout {
                            id: weatherRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                font.family: Core.Theme.fontFamily
                                text: Services.WeatherService.icon || "🌡"
                                font.pixelSize: 31
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    font.family: Core.Theme.fontFamily
                                    text: Services.WeatherService.temp
                                    color: Core.Theme.foreground
                                    font.pixelSize: 21
                                    font.bold: true
                                }

                                Text {
                                    font.family: Core.Theme.fontFamily
                                    text: Services.WeatherService.condition
                                    color: Core.Theme.muted
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Text {
                                font.family: Core.Theme.fontFamily
                                text: "›"
                                color: Core.Theme.muted
                                font.pixelSize: 17
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: networkRow.implicitHeight + 20
                        radius: Math.max(6, Core.Theme.radius - 2)
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)

                        MouseArea {
                            id: networkCardArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.currentWidget = "network"
                                popup.currentWidgetName = "Network"
                            }
                        }
                        PressBounce { pressed: networkCardArea.pressed }

                        RowLayout {
                            id: networkRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                font.family: Core.Theme.fontFamily
                                text: {
                                    if (!Services.NetworkService.connected) return "󰤭"
                                    if (Services.NetworkService.type === "ethernet") return "󰈀"
                                    const s = Services.NetworkService.strength
                                    if (s >= 75) return "󰤨"
                                    if (s >= 50) return "󰤥"
                                    if (s >= 25) return "󰤢"
                                    return "󰤟"
                                }
                                color: Services.NetworkService.connected
                                    ? Core.Theme.foreground : Core.Theme.muted
                                font.pixelSize: 23
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    font.family: Core.Theme.fontFamily
                                    text: Services.NetworkService.connected
                                        ? (Services.NetworkService.ssid || Services.NetworkService.type)
                                        : "Disconnected"
                                    color: Services.NetworkService.connected
                                        ? Core.Theme.foreground : Core.Theme.muted
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Text {
                                    font.family: Core.Theme.fontFamily
                                    visible: Services.TailscaleService.connected
                                    text: Services.TailscaleService.isMullvad
                                        ? "Mullvad VPN active" : "Tailscale connected"
                                    color: Core.Theme.accent
                                    font.pixelSize: 13
                                }
                            }

                            Text {
                                font.family: Core.Theme.fontFamily
                                text: "›"
                                color: Core.Theme.muted
                                font.pixelSize: 17
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: volRow.implicitHeight + 20
                        radius: Math.max(6, Core.Theme.radius - 2)
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)

                        RowLayout {
                            id: volRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                font.family: Core.Theme.fontFamily
                                text: {
                                    if (Services.AudioService.muted) return "󰝟"
                                    const v = Services.AudioService.volume
                                    if (v >= 66) return "󰕾"
                                    if (v >= 33) return "󰖀"
                                    return "󰕿"
                                }
                                color: Services.AudioService.muted
                                    ? Core.Theme.muted : Core.Theme.foreground
                                font.pixelSize: 23

                                MouseArea {
                                    id: muteToggleArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Services.AudioService.toggleMute()
                                }
                                PressBounce { pressed: muteToggleArea.pressed }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 4
                                radius: 2
                                color: Qt.rgba(1, 1, 1, 0.1)

                                Rectangle {
                                    width: parent.width * Services.AudioService.volume / 100
                                    height: parent.height
                                    radius: parent.radius
                                    color: Services.AudioService.muted
                                        ? Core.Theme.muted : Core.Theme.accent
                                }
                            }

                            Text {
                                font.family: Core.Theme.fontFamily
                                text: Services.AudioService.volume + "%"
                                color: Core.Theme.foreground
                                font.pixelSize: 15
                                font.bold: true
                            }
                        }
                    }
                }
            }

            Loader {
                id: panelLoader
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 0
                active: popup.currentWidget !== ""
                visible: active
                source: active
                    ? Qt.resolvedUrl("../widgets/" + popup.currentWidget + "/Panel.qml")
                    : ""
                onStatusChanged: {
                    if (status === Loader.Error)
                        console.warn("Failed to load panel for", popup.currentWidget)
                }
            }
        }
    }
}

