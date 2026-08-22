import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components

Item {
    id: panel

    property string selectedSsid: ""
    property string passwordDraft: ""
    property bool networksExpanded: false
    property bool tailscaleExpanded: false

    readonly property color successColor: Core.Theme.roleColor("success", Core.Theme.accent)
    readonly property color insetFill: Core.Theme.alphaColor(Core.Theme.surfaceHover, Core.UiStyle.flatSurfaces ? 0.32 : 0.54)
    readonly property color insetBorder: Core.Theme.alphaColor(Core.Theme.barOutlineColor, Core.UiStyle.flatSurfaces ? 0.30 : 0.52)

    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Core.UiStyle.spacingSm

        Components.TintedCard {
            Layout.fillWidth: true
            implicitHeight: wifiCol.implicitHeight + Core.UiStyle.spacing2xl
            opacity: Services.NetworkService.connected ? 1.0 : 0.4

            ColumnLayout {
                id: wifiCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Core.UiStyle.spacingMd
                spacing: Core.UiStyle.spacingSm

                RowLayout {
                    spacing: Core.UiStyle.spacingMd

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
                        color: Services.NetworkService.connected ? Core.Theme.accent : Core.Theme.muted
                        font.pixelSize: Core.UiStyle.iconSize + 10
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Core.UiStyle.spacingXs / 2

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: Services.NetworkService.connected
                                ? (Services.NetworkService.ssid || Services.NetworkService.type)
                                : "Disconnected"
                            color: Services.NetworkService.connected ? Core.Theme.foreground : Core.Theme.muted
                            font.pixelSize: Core.UiStyle.fontTitle
                            font.bold: true
                        }

                        Text {
                            font.family: Core.Theme.fontFamily
                            visible: Services.NetworkService.connected
                            text: {
                                let info = Services.NetworkService.ipAddress || ""
                                if (Services.NetworkService.security)
                                    info += (info ? "  " : "") + Services.NetworkService.security
                                return info || "Connected"
                            }
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.fontBody
                        }
                    }

                    Components.ProgressRing {
                        visible: Services.NetworkService.connected && Services.NetworkService.type === "wifi"
                        percent: Services.NetworkService.strength / 100
                        label: Services.NetworkService.strength + "%"
                    }
                }

                Rectangle {
                    visible: Services.NetworkService.connected
                    Layout.fillWidth: true
                    implicitHeight: transferRow.implicitHeight + Core.UiStyle.spacingSm
                    radius: Core.UiStyle.radiusControl
                    color: panel.insetFill
                    border.width: Core.UiStyle.borderWidth
                    border.color: panel.insetBorder

                    RowLayout {
                        id: transferRow
                        anchors.centerIn: parent
                        spacing: Core.UiStyle.spacingXl

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: "󰩟 " + Services.NetworkService.downloadRate
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.fontBody
                        }

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: "󰩠 " + Services.NetworkService.uploadRate
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.fontBody
                        }
                    }
                }
            }
        }

        Components.TintedCard {
            Layout.fillWidth: true
            implicitHeight: selectorCol.implicitHeight + Core.UiStyle.spacing2xl

            ColumnLayout {
                id: selectorCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Core.UiStyle.spacingMd
                spacing: Core.UiStyle.spacingSm

                Item {
                    Layout.fillWidth: true
                    implicitHeight: headerRow.implicitHeight

                    MouseArea {
                        id: networksExpandArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            panel.networksExpanded = !panel.networksExpanded
                            if (panel.networksExpanded) Services.NetworkService.scan()
                        }
                    }
                    Components.PressBounce { pressed: networksExpandArea.pressed }

                    RowLayout {
                        id: headerRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: Core.UiStyle.spacingSm

                        Text {
                            text: panel.networksExpanded ? "󰅀" : "󰅂"
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.iconSize
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Available Networks"
                            color: Core.Theme.foreground
                            font.pixelSize: Core.UiStyle.fontSection
                            font.bold: true
                        }

                        Text {
                            visible: panel.networksExpanded
                            text: Services.NetworkService.scanning ? "…" : "󰑐"
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.iconSize + 2

                            MouseArea {
                                id: networkRescanArea
                                anchors.fill: parent
                                anchors.margins: -Core.UiStyle.spacingSm
                                cursorShape: Qt.PointingHandCursor
                                enabled: !Services.NetworkService.scanning
                                onClicked: Services.NetworkService.scan()
                            }
                            Components.PressBounce { pressed: networkRescanArea.pressed }
                        }
                    }
                }

                Repeater {
                    model: panel.networksExpanded ? Services.NetworkService.accessPoints : []

                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Core.UiStyle.spacingSm

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Core.UiStyle.spacingSm

                            Text {
                                text: modelData.active ? "󰤨" : "󰤢"
                                color: modelData.active ? Core.Theme.accent : Core.Theme.muted
                                font.pixelSize: Core.UiStyle.iconSize + 2
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.ssid
                                color: modelData.active ? Core.Theme.foreground : Core.Theme.muted
                                font.pixelSize: Core.UiStyle.fontBody
                                font.bold: modelData.active
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: modelData.security !== ""
                                text: "󰌾"
                                color: Core.Theme.muted
                                font.pixelSize: Core.UiStyle.iconSize
                            }

                            Text {
                                text: modelData.strength + "%"
                                color: Core.Theme.muted
                                font.pixelSize: Core.UiStyle.fontCaption
                            }

                            MouseArea {
                                id: apRowArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !modelData.active && !Services.NetworkService.connecting
                                onClicked: {
                                    if (modelData.security !== "") {
                                        panel.selectedSsid = panel.selectedSsid === modelData.ssid ? "" : modelData.ssid
                                        panel.passwordDraft = ""
                                    } else {
                                        Services.NetworkService.connectWifi(modelData.ssid, "")
                                    }
                                }
                            }
                            Components.PressBounce { pressed: apRowArea.pressed }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: panel.selectedSsid === modelData.ssid
                            spacing: Core.UiStyle.spacingSm

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: Math.max(Core.UiStyle.controlHeight, pwField.implicitHeight + Core.UiStyle.spacingSm)
                                radius: Core.UiStyle.radiusControl
                                color: panel.insetFill
                                border.width: Core.UiStyle.borderWidth
                                border.color: panel.insetBorder

                                TextInput {
                                    id: pwField
                                    anchors.fill: parent
                                    anchors.leftMargin: Core.UiStyle.spacingMd
                                    anchors.rightMargin: Core.UiStyle.spacingMd
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Core.Theme.foreground
                                    font.pixelSize: Core.UiStyle.fontBody
                                    echoMode: TextInput.Password
                                    text: panel.passwordDraft
                                    onTextChanged: panel.passwordDraft = text
                                    Keys.onReturnPressed: {
                                        Services.NetworkService.connectWifi(modelData.ssid, panel.passwordDraft)
                                        panel.selectedSsid = ""
                                        panel.passwordDraft = ""
                                    }
                                }
                            }

                            Text {
                                text: "Connect"
                                color: Core.Theme.accent
                                font.pixelSize: Core.UiStyle.fontBody
                                font.bold: true

                                MouseArea {
                                    id: connectDraftArea
                                    anchors.fill: parent
                                    anchors.margins: -Core.UiStyle.spacingSm
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Services.NetworkService.connectWifi(modelData.ssid, panel.passwordDraft)
                                        panel.selectedSsid = ""
                                        panel.passwordDraft = ""
                                    }
                                }
                                Components.PressBounce { pressed: connectDraftArea.pressed }
                            }
                        }
                    }
                }

                Text {
                    visible: panel.networksExpanded && Services.NetworkService.accessPoints.length === 0
                    text: Services.NetworkService.scanning ? "Scanning…" : "No networks found"
                    color: Core.Theme.muted
                    font.pixelSize: Core.UiStyle.fontSecondary
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: mullvadCol.implicitHeight + Core.UiStyle.spacing2xl
            radius: Core.UiStyle.radiusSurface
            color: Services.TailscaleService.isMullvad
                ? Core.Theme.alphaColor(panel.successColor, Core.UiStyle.flatSurfaces ? 0.08 : 0.14)
                : panel.insetFill
            border.width: Core.UiStyle.borderWidth
            border.color: Services.TailscaleService.isMullvad
                ? Core.Theme.alphaColor(panel.successColor, 0.42)
                : panel.insetBorder
            opacity: Services.TailscaleService.isMullvad ? 1.0 : 0.5

            ColumnLayout {
                id: mullvadCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Core.UiStyle.spacingMd
                spacing: Core.UiStyle.spacingSm

                RowLayout {
                    spacing: Core.UiStyle.spacingMd

                    Text {
                        font.family: Core.Theme.fontFamily
                        text: "󰦝"
                        color: Services.TailscaleService.isMullvad ? panel.successColor : Core.Theme.muted
                        font.pixelSize: Core.UiStyle.iconSize + 10
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Core.UiStyle.spacingXs / 2

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: "Mullvad VPN"
                            color: Core.Theme.foreground
                            font.pixelSize: Core.UiStyle.fontTitle
                            font.bold: true
                        }

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: Services.TailscaleService.isMullvad ? "Via Tailscale exit node" : "Inactive"
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.fontBody
                        }
                    }

                    Components.StatusPill {
                        active: Services.TailscaleService.isMullvad
                        activeLabel: "CONNECTED"
                        inactiveLabel: "OFF"
                        activeColor: panel.successColor
                    }
                }

                Text {
                    font.family: Core.Theme.fontFamily
                    visible: Services.TailscaleService.isMullvad && Services.TailscaleService.mullvadLocation !== ""
                    text: "Exit: " + Services.TailscaleService.mullvadLocation
                    color: Core.Theme.muted
                    font.pixelSize: Core.UiStyle.fontBody
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: tsCol.implicitHeight + Core.UiStyle.spacing2xl
            radius: Core.UiStyle.radiusSurface
            color: Services.TailscaleService.connected
                ? Core.Theme.alphaColor(Core.Theme.surfaceRaised, Core.UiStyle.flatSurfaces ? 0.56 : 0.82)
                : panel.insetFill
            border.width: Core.UiStyle.borderWidth
            border.color: Services.TailscaleService.connected ? Core.Theme.barOutlineColor : panel.insetBorder
            opacity: Services.TailscaleService.connected ? 1.0 : 0.4

            MouseArea {
                id: tailscaleExpandArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    panel.tailscaleExpanded = !panel.tailscaleExpanded
                    if (panel.tailscaleExpanded) Services.TailscaleService.refreshStatusText()
                }
            }
            Components.PressBounce { pressed: tailscaleExpandArea.pressed }

            ColumnLayout {
                id: tsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Core.UiStyle.spacingMd
                spacing: Core.UiStyle.spacingSm

                RowLayout {
                    spacing: Core.UiStyle.spacingMd

                    Image {
                        source: "../../assets/icons/tailscale.png"
                        Layout.preferredWidth: Core.UiStyle.iconBox + Core.UiStyle.spacingXs
                        Layout.preferredHeight: Core.UiStyle.iconBox + Core.UiStyle.spacingXs
                        smooth: true
                        opacity: Services.TailscaleService.connected ? 1.0 : 0.5
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Core.UiStyle.spacingXs / 2

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: "Tailscale"
                            color: Core.Theme.foreground
                            font.pixelSize: Core.UiStyle.fontTitle
                            font.bold: true
                        }

                        Text {
                            font.family: Core.Theme.fontFamily
                            text: {
                                if (!Services.TailscaleService.running) return "Not installed"
                                if (!Services.TailscaleService.connected) return "Disconnected"
                                return Services.TailscaleService.ipAddress || "Connected"
                            }
                            color: Core.Theme.muted
                            font.pixelSize: Core.UiStyle.fontBody
                        }
                    }

                    Text {
                        font.family: Core.Theme.fontFamily
                        visible: Services.TailscaleService.connected
                        text: Services.TailscaleService.peerCount + " peers"
                        color: Core.Theme.muted
                        font.pixelSize: Core.UiStyle.fontBody
                    }

                    Rectangle {
                        visible: Services.TailscaleService.connected
                        width: tsPillText.implicitWidth + Core.UiStyle.spacingLg
                        height: tsPillText.implicitHeight + Core.UiStyle.spacingXs
                        radius: Core.UiStyle.radiusControl
                        color: Core.Theme.accent

                        Text {
                            id: tsPillText
                            anchors.centerIn: parent
                            text: "CONNECTED"
                            color: Core.Theme.background
                            font.pixelSize: Core.UiStyle.fontCaption
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                    }
                }

                Text {
                    visible: Services.TailscaleService.connected && Services.TailscaleService.tailnet !== ""
                    text: "Tailnet: " + Services.TailscaleService.tailnet
                    color: Core.Theme.muted
                    font.pixelSize: Core.UiStyle.fontBody
                }

                Rectangle {
                    visible: panel.tailscaleExpanded
                    Layout.fillWidth: true
                    implicitHeight: 140
                    radius: Core.UiStyle.radiusSurface
                    color: Core.Theme.alphaColor(Core.Theme.background, 0.52)
                    border.width: Core.UiStyle.borderWidth
                    border.color: panel.insetBorder
                    clip: true

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: Core.UiStyle.spacingSm
                        contentWidth: statusOutput.implicitWidth
                        contentHeight: statusOutput.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Text {
                            id: statusOutput
                            text: Services.TailscaleService.statusLoading ? "Loading…" : (Services.TailscaleService.statusText || "No output")
                            color: Core.Theme.foreground
                            font.family: "monospace"
                            font.pixelSize: Core.UiStyle.fontBody
                            wrapMode: Text.NoWrap
                        }
                    }
                }
            }
        }
    }
}
