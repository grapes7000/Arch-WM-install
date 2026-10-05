import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components

Item {
    id: panel
    implicitHeight: layout.implicitHeight
    readonly property var selectableDevices: Services.BluetoothService.devices.filter(
        device => device.paired || device.connected)
    readonly property var nearbyDevices: Services.BluetoothService.devices.filter(
        device => !device.paired && !device.connected)

    function deviceIcon(device) {
        if (device.icon.indexOf("audio") >= 0 || device.icon.indexOf("head") >= 0) return "󰋋"
        if (device.icon.indexOf("input") >= 0 || device.icon.indexOf("mouse") >= 0) return "󰍽"
        if (device.icon.indexOf("phone") >= 0) return "󰏲"
        return "󰂯"
    }

    ColumnLayout {
        id: layout
        anchors.left: parent.left; anchors.right: parent.right
        spacing: Core.UiStyle.spacingSm
        Components.TintedCard {
            Layout.fillWidth: true
            implicitHeight: header.implicitHeight + Core.UiStyle.spacing2xl
            active: Services.BluetoothService.powered
            tintColor: Core.Theme.accent
            RowLayout {
                id: header
                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Core.UiStyle.spacingMd
                spacing: Core.UiStyle.spacingMd
                Text { font.family: Core.Theme.fontFamily; text: Services.BluetoothService.powered ? "󰂯" : "󰂲"; color: Services.BluetoothService.powered ? Core.Theme.accent : Core.Theme.muted; font.pixelSize: Core.UiStyle.iconSize + 10 }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: Core.UiStyle.spacingXs / 2
                    Text { text: "Bluetooth"; color: Core.Theme.foreground; font.pixelSize: Core.UiStyle.fontTitle; font.bold: true }
                    Text { text: Services.BluetoothService.powered ? (Services.BluetoothService.discovering ? "Looking for devices…" : "Ready to connect") : "Turn Bluetooth on to select a device"; color: Core.Theme.muted; font.pixelSize: Core.UiStyle.fontBody }
                }
                Components.StatusPill {
                    active: Services.BluetoothService.powered; activeLabel: "ON"; inactiveLabel: "OFF"; pulse: Services.BluetoothService.discovering && Core.UiStyle.motionPlayful
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !Services.BluetoothService.busy; onClicked: Services.BluetoothService.setPower(!Services.BluetoothService.powered) }
                }
            }
        }
        Components.TintedCard {
            visible: Services.BluetoothService.powered
            Layout.fillWidth: true
            implicitHeight: deviceList.implicitHeight + Core.UiStyle.spacing2xl
            ColumnLayout {
                id: deviceList
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: Core.UiStyle.spacingMd
                spacing: Core.UiStyle.spacingSm
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Paired Devices"; color: Core.Theme.foreground; font.pixelSize: Core.UiStyle.fontSection; font.bold: true; Layout.fillWidth: true }
                    Text {
                        text: Services.BluetoothService.discovering ? "Scanning…" : "󰑐 Scan"
                        color: Services.BluetoothService.busy ? Core.Theme.muted : Core.Theme.accent; font.pixelSize: Core.UiStyle.fontBody; font.bold: true
                        MouseArea { anchors.fill: parent; anchors.margins: -Core.UiStyle.spacingSm; cursorShape: Qt.PointingHandCursor; enabled: !Services.BluetoothService.busy; onClicked: Services.BluetoothService.scan() }
                    }
                }
                Repeater {
                    model: panel.selectableDevices
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: row.implicitHeight + Core.UiStyle.spacingSm * 2
                        radius: Core.UiStyle.radiusControl
                        color: modelData.connected ? Core.Theme.alphaColor(Core.Theme.accent, Core.UiStyle.flatSurfaces ? 0.12 : 0.18) : Core.Theme.alphaColor(Core.Theme.surfaceHover, Core.UiStyle.flatSurfaces ? 0.26 : 0.46)
                        border.width: Core.UiStyle.borderWidth
                        border.color: modelData.connected ? Core.Theme.alphaColor(Core.Theme.accent, 0.55) : Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.36)
                        RowLayout {
                            id: row
                            anchors.fill: parent; anchors.margins: Core.UiStyle.spacingSm
                            spacing: Core.UiStyle.spacingSm
                            Text { text: panel.deviceIcon(modelData); color: modelData.connected ? Core.Theme.accent : Core.Theme.muted; font.pixelSize: Core.UiStyle.iconSize + 3 }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 0
                                Text { Layout.fillWidth: true; text: modelData.advertisedName || modelData.alias || modelData.name || "Unnamed Bluetooth device"; color: Core.Theme.foreground; font.pixelSize: Core.UiStyle.fontBody; font.bold: modelData.connected; elide: Text.ElideRight }
                                Text { text: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : modelData.address); color: Core.Theme.muted; font.pixelSize: Core.UiStyle.fontCaption }
                            }
                            Text { text: modelData.connected ? "Disconnect" : "Connect"; color: Services.BluetoothService.busy ? Core.Theme.muted : Core.Theme.accent; font.pixelSize: Core.UiStyle.fontBody; font.bold: true }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !Services.BluetoothService.busy; onClicked: modelData.connected ? Services.BluetoothService.disconnect(modelData.address) : Services.BluetoothService.connect(modelData.address) }
                    }
                }
                Components.EmptyState { visible: panel.selectableDevices.length === 0; Layout.fillWidth: true; icon: "󰂲"; message: "No paired devices found" }
            }
        }
        Components.TintedCard {
            visible: Services.BluetoothService.powered && panel.nearbyDevices.length > 0
            Layout.fillWidth: true
            implicitHeight: nearbyList.implicitHeight + Core.UiStyle.spacing2xl
            ColumnLayout {
                id: nearbyList
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: Core.UiStyle.spacingMd
                spacing: Core.UiStyle.spacingSm
                Text { text: "Nearby Devices"; color: Core.Theme.foreground; font.pixelSize: Core.UiStyle.fontSection; font.bold: true }
                Text { text: "Scan finds devices; pairing saves one for quick switching."; color: Core.Theme.muted; font.pixelSize: Core.UiStyle.fontCaption; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                Repeater {
                    model: panel.nearbyDevices
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: nearbyRow.implicitHeight + Core.UiStyle.spacingSm * 2
                        radius: Core.UiStyle.radiusControl
                        color: Core.Theme.alphaColor(Core.Theme.surfaceHover, Core.UiStyle.flatSurfaces ? 0.26 : 0.46)
                        border.width: Core.UiStyle.borderWidth
                        border.color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.36)
                        RowLayout {
                            id: nearbyRow
                            anchors.fill: parent; anchors.margins: Core.UiStyle.spacingSm
                            spacing: Core.UiStyle.spacingSm
                            Text { text: panel.deviceIcon(modelData); color: Core.Theme.muted; font.pixelSize: Core.UiStyle.iconSize + 3 }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 0
                                Text { Layout.fillWidth: true; text: modelData.advertisedName || modelData.alias || modelData.name || "Unnamed Bluetooth device"; color: Core.Theme.foreground; font.pixelSize: Core.UiStyle.fontBody; elide: Text.ElideRight }
                                Text { text: modelData.address; color: Core.Theme.muted; font.pixelSize: Core.UiStyle.fontCaption }
                            }
                            Text { text: "Pair"; color: Services.BluetoothService.busy ? Core.Theme.muted : Core.Theme.accent; font.pixelSize: Core.UiStyle.fontBody; font.bold: true }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !Services.BluetoothService.busy; onClicked: Services.BluetoothService.pair(modelData.address) }
                    }
                }
            }
        }
        Components.EmptyState { visible: Services.BluetoothService.error !== ""; Layout.fillWidth: true; icon: "󰂲"; message: Services.BluetoothService.error }
    }
}
