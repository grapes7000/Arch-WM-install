import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components

ColumnLayout {
    id: root
    implicitHeight: 420
    spacing: Core.Theme.gap
    property string selectedSsid: ""

    function clearPassword() { passwordField.text = "" }
    onVisibleChanged: if (!visible) clearPassword()

    Text { font.family: Core.Theme.fontFamily; text: "Network"; color: Core.Theme.foreground; font.pixelSize: 18; font.bold: true }
    Text {
        font.family: Core.Theme.fontFamily
        Layout.fillWidth: true
        text: Services.NetworkService.connected
            ? (Services.NetworkService.ssid || Services.NetworkService.type) + " · " + (Services.NetworkService.ipAddress || "Connected")
            : "Disconnected"
        color: Services.NetworkService.connected ? Core.Theme.foreground : Core.Theme.muted
        elide: Text.ElideRight
    }
    Text {
        font.family: Core.Theme.fontFamily
        visible: Services.TailscaleService.connected
        text: Services.TailscaleService.isMullvad ? "Mullvad active" : "Tailscale connected"
        color: Core.Theme.accent
        font.pixelSize: 11
    }

    RowLayout {
        Layout.fillWidth: true
        Text { font.family: Core.Theme.fontFamily; text: "Available Wi-Fi"; color: Core.Theme.muted; font.pixelSize: 10; font.bold: true }
        Item { Layout.fillWidth: true }
        Text { font.family: Core.Theme.fontFamily; text: Services.NetworkService.scanning ? "Scanning…" : "Refresh"; color: Core.Theme.accent; MouseArea { id: refreshArea; anchors.fill: parent; enabled: !Services.NetworkService.scanning; onClicked: Services.NetworkService.scan() } Components.PressBounce { pressed: refreshArea.pressed } }
    }

    ListView {
        id: accessPointList
        Layout.fillWidth: true
        Layout.preferredHeight: 180
        clip: true
        spacing: Core.Theme.gap / 2
        model: Services.NetworkService.accessPoints
        delegate: Rectangle {
            required property var modelData
            width: accessPointList.width
            height: 36
            radius: Core.Theme.radius
            color: root.selectedSsid === modelData.ssid ? Core.Theme.accent2 : Core.Theme.background
            RowLayout {
                anchors.fill: parent; anchors.margins: Core.Theme.gap
                Text { font.family: Core.Theme.fontFamily; Layout.fillWidth: true; text: modelData.ssid || "Hidden network"; color: Core.Theme.foreground; elide: Text.ElideRight }
                Text { font.family: Core.Theme.fontFamily; text: (modelData.strength || 0) + "%"; color: Core.Theme.muted; font.pixelSize: 10 }
            }
            MouseArea { id: apArea; anchors.fill: parent; onClicked: { root.selectedSsid = modelData.ssid || ""; passwordField.forceActiveFocus() } }
            Components.PressBounce { pressed: apArea.pressed }
        }
    }

    TextField {
        id: passwordField
        Layout.fillWidth: true
        visible: root.selectedSsid !== ""
        placeholderText: "Password for " + root.selectedSsid
        echoMode: TextInput.Password
        color: Core.Theme.foreground
        background: Rectangle { color: Core.Theme.background; radius: Core.Theme.radius; border.width: Core.Theme.borderWidth; border.color: passwordField.activeFocus ? Core.Theme.accent : Core.Theme.accent2 }
        onTextChanged: passwordExpiry.restart()
    }
    Timer { id: passwordExpiry; interval: 15000; onTriggered: root.clearPassword() }
    Text {
        font.family: Core.Theme.fontFamily
        visible: root.selectedSsid !== ""
        text: Services.NetworkService.connecting ? "Connecting…" : "Connect"
        color: Core.Theme.accent
        font.bold: true
        MouseArea {
            id: connectArea
            anchors.fill: parent
            enabled: !Services.NetworkService.connecting
            onClicked: {
                Services.NetworkService.connectWifi(root.selectedSsid, passwordField.text)
                root.clearPassword()
            }
        }
        Components.PressBounce { pressed: connectArea.pressed }
    }
    Text { font.family: Core.Theme.fontFamily; visible: Services.NetworkService.error !== ""; text: Services.NetworkService.error; color: Core.Theme.urgent; font.pixelSize: 10; wrapMode: Text.Wrap; Layout.fillWidth: true }
}

