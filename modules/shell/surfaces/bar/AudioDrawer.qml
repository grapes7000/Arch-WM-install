import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

ColumnLayout {
    implicitHeight: 350
    spacing: Core.Theme.gap

    Text { font.family: Core.Theme.fontFamily; text: "Audio"; color: Core.Theme.foreground; font.pixelSize: 18; font.bold: true }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text { font.family: Core.Theme.fontFamily; text: Services.MprisService.title || "Nothing playing"; color: Core.Theme.foreground; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
        Text { font.family: Core.Theme.fontFamily; text: Services.MprisService.artist || "No active player"; color: Core.Theme.muted; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Core.Theme.gap * 2
        Text { font.family: Core.Theme.fontFamily; text: "󰒮"; color: Services.MprisService.canPrev ? Core.Theme.foreground : Core.Theme.muted; font.pixelSize: 20; MouseArea { anchors.fill: parent; enabled: Services.MprisService.canPrev; onClicked: Services.MprisService.previous() } }
        Text { font.family: Core.Theme.fontFamily; text: Services.MprisService.status === "Playing" ? "󰏤" : "󰐊"; color: Core.Theme.accent; font.pixelSize: 24; MouseArea { anchors.fill: parent; onClicked: Services.MprisService.playPause() } }
        Text { font.family: Core.Theme.fontFamily; text: "󰒭"; color: Services.MprisService.canNext ? Core.Theme.foreground : Core.Theme.muted; font.pixelSize: 20; MouseArea { anchors.fill: parent; enabled: Services.MprisService.canNext; onClicked: Services.MprisService.next() } }
    }

    Row {
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        spacing: 3
        Repeater {
            model: Services.CavaService.available ? Services.CavaService.bars : []
            Rectangle {
                required property real modelData
                width: Math.max(2, (parent.width - 3 * Math.max(0, Services.CavaService.bars.length - 1)) / Math.max(1, Services.CavaService.bars.length))
                height: Math.max(2, parent.height * modelData)
                anchors.bottom: parent.bottom
                radius: 2
                color: Core.Theme.accent
            }
        }
        Text { font.family: Core.Theme.fontFamily; visible: !Services.CavaService.available; text: "Visualizer unavailable"; color: Core.Theme.muted; font.pixelSize: 11 }
    }

    RowLayout {
        Layout.fillWidth: true
        Text { font.family: Core.Theme.fontFamily; text: Services.AudioService.muted ? "󰝟" : "󰕾"; color: Core.Theme.foreground; font.pixelSize: 18; MouseArea { anchors.fill: parent; onClicked: Services.AudioService.toggleMute() } }
        Rectangle {
            Layout.fillWidth: true; height: 8; radius: 4; color: Core.Theme.background
            Rectangle { width: parent.width * Services.AudioService.volume / 100; height: parent.height; radius: parent.radius; color: Services.AudioService.muted ? Core.Theme.muted : Core.Theme.accent }
        }
        Text { font.family: Core.Theme.fontFamily; text: Services.AudioService.volume + "%"; color: Core.Theme.foreground; font.pixelSize: 11 }
    }

    Text { font.family: Core.Theme.fontFamily; text: "Outputs"; color: Core.Theme.muted; font.pixelSize: 10; font.bold: true }
    Repeater {
        model: Services.AudioService.sinks
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Text { font.family: Core.Theme.fontFamily; Layout.fillWidth: true; text: modelData.name || modelData.id; color: Core.Theme.foreground; elide: Text.ElideRight; font.pixelSize: 11 }
            Text { font.family: Core.Theme.fontFamily; text: modelData.volume + "%"; color: Core.Theme.muted; font.pixelSize: 10 }
        }
    }
}

