import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

Item {
    id: root
    property var context: ({ variant: "standard", settings: ({}), locked: false,
        allows: function() { return false } })
    readonly property var connectedDevice: Services.BluetoothService.devices.find(device => device.connected)
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    MouseArea { anchors.fill: parent; z: 10; enabled: context.allows("drawer.open"); cursorShape: Qt.PointingHandCursor; onClicked: context.request("drawer.open", { kind: "bluetooth", anchorItem: root }) }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Core.UiStyle.spacingXs
        Text {
            font.family: Core.Theme.fontFamily
            text: Services.BluetoothService.powered ? (root.connectedDevice ? "󰂱" : "󰂯") : "󰂲"
            color: root.connectedDevice ? Core.Theme.foreground : Core.Theme.muted
            font.pixelSize: context.variant === "compact" ? Core.UiStyle.iconSize + 4 : Core.UiStyle.iconSize + 7
        }
        Text {
            visible: context.variant !== "compact"
            text: root.connectedDevice
                ? (root.connectedDevice.advertisedName || root.connectedDevice.alias || root.connectedDevice.name)
                : (Services.BluetoothService.powered ? "Bluetooth" : "Off")
            color: root.connectedDevice ? Core.Theme.foreground : Core.Theme.muted
            font.pixelSize: Core.UiStyle.fontBody
            elide: Text.ElideRight
            Layout.maximumWidth: 100
        }
    }
}
