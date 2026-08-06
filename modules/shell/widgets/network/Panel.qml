import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

Item {
    id: panel

    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Connection"
                color: Core.Theme.accent
                font.pixelSize: 11
                font.bold: true
                font.capitalization: Font.AllUppercase
            }

            RowLayout {
                spacing: 10

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
                        ? Core.Theme.foreground : Core.Theme.muted
                    font.pixelSize: 24
                }

                ColumnLayout {
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
                            && Services.NetworkService.type === "wifi"
                        text: "Signal: " + Services.NetworkService.strength + "%"
                        color: Core.Theme.muted
                        font.pixelSize: 11
                    }
                }
            }

            Rectangle {
                visible: Services.NetworkService.connected
                    && Services.NetworkService.type === "wifi"
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.1)

                Rectangle {
                    width: parent.width * Services.NetworkService.strength / 100
                    height: parent.height
                    radius: parent.radius
                    color: {
                        const s = Services.NetworkService.strength
                        if (s >= 75) return Core.Theme.accent
                        if (s >= 50) return Core.Theme.accent2
                        return Core.Theme.urgent
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Core.Theme.muted
            opacity: 0.2
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Tailscale"
                color: Core.Theme.accent
                font.pixelSize: 11
                font.bold: true
                font.capitalization: Font.AllUppercase
            }

            RowLayout {
                spacing: 10

                Text {
                    text: "󰖂"
                    color: Services.TailscaleService.connected
                        ? Core.Theme.accent : Core.Theme.muted
                    font.pixelSize: 20
                }

                ColumnLayout {
                    spacing: 2

                    Text {
                        text: Services.TailscaleService.connected
                            ? "Connected" : (Services.TailscaleService.running
                                ? "Not connected" : "Not running")
                        color: Services.TailscaleService.connected
                            ? Core.Theme.foreground : Core.Theme.muted
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        visible: Services.TailscaleService.tailnet !== ""
                        text: Services.TailscaleService.tailnet
                        color: Core.Theme.muted
                        font.pixelSize: 11
                    }
                }
            }

            RowLayout {
                visible: Services.TailscaleService.connected
                spacing: 8

                Text {
                    text: "Exit Node"
                    color: Core.Theme.muted
                    font.pixelSize: 12
                }

                Text {
                    text: Services.TailscaleService.exitNodeActive
                        ? Services.TailscaleService.exitNodeName : "None"
                    color: Services.TailscaleService.exitNodeActive
                        ? Core.Theme.accent : Core.Theme.muted
                    font.pixelSize: 12
                    font.bold: Services.TailscaleService.exitNodeActive
                }
            }
        }

        Rectangle {
            visible: Services.TailscaleService.isMullvad
            Layout.fillWidth: true
            height: 1
            color: Core.Theme.muted
            opacity: 0.2
        }

        ColumnLayout {
            visible: Services.TailscaleService.isMullvad
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Mullvad VPN"
                color: Core.Theme.accent
                font.pixelSize: 11
                font.bold: true
                font.capitalization: Font.AllUppercase
            }

            RowLayout {
                spacing: 10

                Text {
                    text: "󰌾"
                    color: Core.Theme.accent
                    font.pixelSize: 20
                }

                ColumnLayout {
                    spacing: 2

                    Text {
                        text: "Active"
                        color: Core.Theme.foreground
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        visible: Services.TailscaleService.mullvadLocation !== ""
                        text: "Exit: " + Services.TailscaleService.mullvadLocation
                        color: Core.Theme.muted
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
