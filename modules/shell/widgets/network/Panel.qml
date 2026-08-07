import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

Item {
    id: panel

    property string selectedSsid: ""
    property string passwordDraft: ""
    property bool networksExpanded: false
    property bool tailscaleExpanded: false

    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: wifiCol.implicitHeight + 24
            radius: Math.max(6, Core.Theme.radius - 2)
            color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06)
            opacity: Services.NetworkService.connected ? 1.0 : 0.4

            ColumnLayout {
                id: wifiCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    spacing: 12

                    Text {
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
                            ? Core.Theme.accent : Core.Theme.muted
                        font.pixelSize: 22
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: Services.NetworkService.connected
                                ? (Services.NetworkService.ssid || Services.NetworkService.type)
                                : "Disconnected"
                            color: Services.NetworkService.connected
                                ? Core.Theme.foreground : Core.Theme.muted
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            visible: Services.NetworkService.connected
                            text: {
                                let info = Services.NetworkService.ipAddress || ""
                                if (Services.NetworkService.security)
                                    info += (info ? "  " : "") + Services.NetworkService.security
                                return info || "Connected"
                            }
                            color: Core.Theme.muted
                            font.pixelSize: 10
                        }
                    }

                    Item {
                        visible: Services.NetworkService.connected
                            && Services.NetworkService.type === "wifi"
                        width: 42
                        height: 42

                        Canvas {
                            id: signalRing
                            anchors.fill: parent
                            property real percent: Services.NetworkService.strength / 100
                            onPercentChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d")
                                var cx = width / 2
                                var cy = height / 2
                                var r = (Math.min(width, height) - 6) / 2
                                ctx.clearRect(0, 0, width, height)

                                ctx.beginPath()
                                ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                                ctx.lineWidth = 4
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.06)
                                ctx.stroke()

                                if (percent > 0) {
                                    ctx.beginPath()
                                    var start = -Math.PI / 2
                                    ctx.arc(cx, cy, r, start, start + 2 * Math.PI * percent)
                                    ctx.lineWidth = 4
                                    ctx.strokeStyle = Core.Theme.accent
                                    ctx.lineCap = "round"
                                    ctx.stroke()
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Services.NetworkService.strength + "%"
                            color: Core.Theme.foreground
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    visible: Services.NetworkService.connected
                    Layout.fillWidth: true
                    implicitHeight: transferRow.implicitHeight + 8
                    radius: 999
                    color: Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.06)

                    RowLayout {
                        id: transferRow
                        anchors.centerIn: parent
                        spacing: 20

                        Text {
                            text: "󰩟 " + Services.NetworkService.downloadRate
                            color: Core.Theme.muted
                            font.pixelSize: 10
                        }

                        Text {
                            text: "󰩠 " + Services.NetworkService.uploadRate
                            color: Core.Theme.muted
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: selectorCol.implicitHeight + 24
            radius: Math.max(6, Core.Theme.radius - 2)
            color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06)

            ColumnLayout {
                id: selectorCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                Item {
                    Layout.fillWidth: true
                    implicitHeight: headerRow.implicitHeight

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            panel.networksExpanded = !panel.networksExpanded
                            if (panel.networksExpanded) Services.NetworkService.scan()
                        }
                    }

                    RowLayout {
                        id: headerRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8

                        Text {
                            text: panel.networksExpanded ? "󰅀" : "󰅂"
                            color: Core.Theme.muted
                            font.pixelSize: 12
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Available Networks"
                            color: Core.Theme.foreground
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            visible: panel.networksExpanded
                            text: Services.NetworkService.scanning ? "…" : "󰑐"
                            color: Core.Theme.muted
                            font.pixelSize: 14

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                enabled: !Services.NetworkService.scanning
                                onClicked: Services.NetworkService.scan()
                            }
                        }
                    }
                }

                Repeater {
                    model: panel.networksExpanded ? Services.NetworkService.accessPoints : []

                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: modelData.active ? "󰤨" : "󰤢"
                                color: modelData.active ? Core.Theme.accent : Core.Theme.muted
                                font.pixelSize: 14
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.ssid
                                color: modelData.active ? Core.Theme.foreground : Core.Theme.muted
                                font.pixelSize: 12
                                font.bold: modelData.active
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: modelData.security !== ""
                                text: "󰌾"
                                color: Core.Theme.muted
                                font.pixelSize: 11
                            }

                            Text {
                                text: modelData.strength + "%"
                                color: Core.Theme.muted
                                font.pixelSize: 10
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !modelData.active && !Services.NetworkService.connecting
                                onClicked: {
                                    if (modelData.security !== "") {
                                        panel.selectedSsid = panel.selectedSsid === modelData.ssid
                                            ? "" : modelData.ssid
                                        panel.passwordDraft = ""
                                    } else {
                                        Services.NetworkService.connectWifi(modelData.ssid, "")
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: panel.selectedSsid === modelData.ssid
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: pwField.implicitHeight + 10
                                radius: 999
                                color: Qt.rgba(1, 1, 1, 0.06)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.1)

                                TextInput {
                                    id: pwField
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Core.Theme.foreground
                                    font.pixelSize: 11
                                    echoMode: TextInput.Password
                                    text: panel.passwordDraft
                                    onTextChanged: panel.passwordDraft = text
                                    Keys.onReturnPressed: {
                                        Services.NetworkService.connectWifi(
                                            modelData.ssid, panel.passwordDraft)
                                        panel.selectedSsid = ""
                                        panel.passwordDraft = ""
                                    }
                                }
                            }

                            Text {
                                text: "Connect"
                                color: Core.Theme.accent
                                font.pixelSize: 11
                                font.bold: true

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Services.NetworkService.connectWifi(
                                            modelData.ssid, panel.passwordDraft)
                                        panel.selectedSsid = ""
                                        panel.passwordDraft = ""
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: panel.networksExpanded && Services.NetworkService.accessPoints.length === 0
                    text: Services.NetworkService.scanning ? "Scanning…" : "No networks found"
                    color: Core.Theme.muted
                    font.pixelSize: 11
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: mullvadCol.implicitHeight + 24
            radius: Math.max(6, Core.Theme.radius - 2)
            color: Services.TailscaleService.isMullvad
                ? Qt.rgba(0.2, 0.8, 0.4, 0.06) : Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: Services.TailscaleService.isMullvad
                ? Qt.rgba(0.2, 0.8, 0.4, 0.3) : Qt.rgba(1, 1, 1, 0.06)
            opacity: Services.TailscaleService.isMullvad ? 1.0 : 0.5

            ColumnLayout {
                id: mullvadCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    spacing: 12

                    Text {
                        text: "󰦝"
                        color: Services.TailscaleService.isMullvad
                            ? Qt.rgba(0.2, 0.8, 0.4, 1.0) : Core.Theme.muted
                        font.pixelSize: 22
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Mullvad VPN"
                            color: Core.Theme.foreground
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            text: Services.TailscaleService.isMullvad
                                ? "Via Tailscale exit node" : "Inactive"
                            color: Core.Theme.muted
                            font.pixelSize: 10
                        }
                    }

                    Rectangle {
                        width: pillText.implicitWidth + 20
                        height: pillText.implicitHeight + 6
                        radius: 999
                        color: Services.TailscaleService.isMullvad
                            ? Qt.rgba(0.2, 0.8, 0.4, 1.0) : Qt.rgba(1, 1, 1, 0.06)

                        property bool pulseState: false

                        Timer {
                            running: Services.TailscaleService.isMullvad
                            interval: 1500
                            repeat: true
                            onTriggered: parent.pulseState = !parent.pulseState
                        }

                        opacity: Services.TailscaleService.isMullvad
                            ? (pulseState ? 1.0 : 0.6) : 1.0

                        Behavior on opacity {
                            NumberAnimation { duration: 750; easing.type: Easing.InOutQuad }
                        }

                        Text {
                            id: pillText
                            anchors.centerIn: parent
                            text: Services.TailscaleService.isMullvad ? "CONNECTED" : "OFF"
                            color: Services.TailscaleService.isMullvad
                                ? Core.Theme.background : Core.Theme.muted
                            font.pixelSize: 8
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                    }
                }

                Text {
                    visible: Services.TailscaleService.isMullvad
                        && Services.TailscaleService.mullvadLocation !== ""
                    text: "Exit: " + Services.TailscaleService.mullvadLocation
                    color: Core.Theme.muted
                    font.pixelSize: 10
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: tsCol.implicitHeight + 24
            radius: Math.max(6, Core.Theme.radius - 2)
            color: Services.TailscaleService.connected
                ? Qt.rgba(0, 0, 0, 0.2) : Qt.rgba(1, 1, 1, 0.04)
            border.width: Services.TailscaleService.connected ? 2 : 1
            border.color: Services.TailscaleService.connected
                ? Qt.rgba(0, 0, 0, 1.0) : Qt.rgba(1, 1, 1, 0.06)
            opacity: Services.TailscaleService.connected ? 1.0 : 0.4

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    panel.tailscaleExpanded = !panel.tailscaleExpanded
                    if (panel.tailscaleExpanded) Services.TailscaleService.refreshStatusText()
                }
            }

            ColumnLayout {
                id: tsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    spacing: 12

                    Image {
                        source: "../../assets/icons/tailscale.png"
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        smooth: true
                        opacity: Services.TailscaleService.connected ? 1.0 : 0.5
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Tailscale"
                            color: Core.Theme.foreground
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            text: {
                                if (!Services.TailscaleService.running) return "Not installed"
                                if (!Services.TailscaleService.connected) return "Disconnected"
                                return Services.TailscaleService.ipAddress || "Connected"
                            }
                            color: Core.Theme.muted
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        visible: Services.TailscaleService.connected
                        text: Services.TailscaleService.peerCount + " peers"
                        color: Core.Theme.muted
                        font.pixelSize: 10
                    }

                    Rectangle {
                        visible: Services.TailscaleService.connected
                        width: tsPillText.implicitWidth + 20
                        height: tsPillText.implicitHeight + 6
                        radius: 999
                        color: Qt.rgba(0, 0, 0, 1.0)

                        Text {
                            id: tsPillText
                            anchors.centerIn: parent
                            text: "CONNECTED"
                            color: "white"
                            font.pixelSize: 8
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                    }
                }

                Text {
                    visible: Services.TailscaleService.connected
                        && Services.TailscaleService.tailnet !== ""
                    text: "Tailnet: " + Services.TailscaleService.tailnet
                    color: Core.Theme.muted
                    font.pixelSize: 10
                }

                Rectangle {
                    visible: panel.tailscaleExpanded
                    Layout.fillWidth: true
                    implicitHeight: 140
                    radius: Math.max(4, Core.Theme.radius - 4)
                    color: Qt.rgba(0, 0, 0, 0.3)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    clip: true

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 8
                        contentWidth: statusOutput.implicitWidth
                        contentHeight: statusOutput.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Text {
                            id: statusOutput
                            text: Services.TailscaleService.statusLoading
                                ? "Loading…" : (Services.TailscaleService.statusText || "No output")
                            color: Core.Theme.foreground
                            font.family: "monospace"
                            font.pixelSize: 10
                            wrapMode: Text.NoWrap
                        }
                    }
                }
            }
        }
    }
}
