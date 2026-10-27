import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../core" as Core
import "../../services" as Services
import "../../surfaces/desktop" as Desktop
import "../tray" as Tray
Item {
    id: root
    property var context
    readonly property var targetScreen: context.settings.screen || null
    readonly property bool bottom: context.settings.position === "bottom"
    readonly property var assets: context.settings.assets || ({})
    implicitWidth: 900
    implicitHeight: bottom ? 37 : 25
    function run(entry) {
        if (context.locked || !entry || !entry.command || !entry.command.length) return
        Quickshell.execDetached(entry.command)
    }
    Desktop.DockModel {
        id: tasks
        monitorName: root.targetScreen ? root.targetScreen.name : ""
        sourceToplevels: Hyprland.toplevels
        desktopEntries: DesktopEntries.applications
        favoriteIds: []
        focusedWorkspace: Hyprland.focusedWorkspace
    }
    RowLayout {
        anchors.fill: parent
        spacing: 4
        ClassicButton {
            visible: root.bottom
            label: "★ Applications"
            icon: root.assets.star || ""
            Layout.preferredWidth: 66; Layout.fillHeight: true
            onClicked: Core.InteractiveShellController.launcher("toggle", root.targetScreen)
        }
        ClassicButton {
            visible: !root.bottom
            label: "Trash"; icon: "user-trash"
            Layout.preferredWidth: 25; Layout.fillHeight: true
            onClicked: root.run({command: ["gio", "open", "trash:///"]})
        }
        // The running-window strip shrinks before pinned launchers do.
        Flickable {
            visible: root.bottom
            Layout.preferredWidth: Math.min(180, taskRow.width)
            Layout.maximumWidth: 180
            Layout.fillHeight: true
            clip: true
            contentWidth: taskRow.width; contentHeight: height
            Row {
                id: taskRow
                height: parent.height; spacing: 3
                Repeater {
                    model: tasks.groups
                    ClassicButton {
                        required property var modelData
                        property int cycle: 0
                        width: 32; height: taskRow.height
                        label: modelData.name || modelData.key
                        icon: modelData.icon || "application-x-executable"
                        selected: modelData.active
                        onClicked: {
                            if (context.locked || !modelData.windows.length) return
                            const w = modelData.windows[cycle++ % modelData.windows.length]
                            if (w.wayland) w.wayland.activate()
                            else if (w.address) Hyprland.dispatch("focuswindow address:" + w.address)
                        }
                    }
                }
            }
        }
        Item { visible: !root.bottom; Layout.fillWidth: true }
        ClassicButton {
            visible: !root.bottom
            label: "Battery"; icon: "battery"
            Layout.preferredWidth: batteryText.implicitWidth + 34; Layout.fillHeight: true
            Text { id: batteryText; anchors.right: parent.right; anchors.rightMargin: 3; anchors.verticalCenter: parent.verticalCenter; text: Services.PowerService.available && Services.PowerService.percent >= 0 ? Services.PowerService.percent + "%" : "AC"; color: "black" }
            onClicked: context.request("drawer.open", {kind: "battery", anchorItem: root})
        }
        Rectangle {
            visible: !root.bottom
            color: "#bfbfbf"; border.color: "#111111"
            Layout.preferredWidth: timeText.implicitWidth + 12; Layout.fillHeight: true
            Text { id: timeText; anchors.centerIn: parent; text: Qt.formatTime(clock.date, "h:mm:ss ap"); color: "black"; font.family: "More Perfect DOS VGA"; font.italic: true; font.pixelSize: 21 }
            SystemClock { id: clock; precision: SystemClock.Seconds }
        }
        ClassicButton {
            visible: !root.bottom
            label: "Volume " + Services.AudioService.volume + "%"; icon: Services.AudioService.muted ? "audio-volume-muted" : "audio-volume-high"
            Layout.preferredWidth: 25; Layout.fillHeight: true
            onClicked: context.request("drawer.open", {kind: "audio", anchorItem: root})
            WheelHandler { onWheel: event => Services.AudioService.adjustVolume(event.angleDelta.y > 0 ? 5 : -5) }
        }
        Tray.Widget { visible: !root.bottom; context: root.context; Layout.preferredWidth: implicitWidth; Layout.fillHeight: true }
        ClassicButton {
            visible: !root.bottom
            label: "Music"; icon: "multimedia-player"
            Layout.preferredWidth: 25; Layout.fillHeight: true
            onClicked: context.request("drawer.open", {kind: "media", anchorItem: root})
        }
        Item { visible: !root.bottom; Layout.fillWidth: true }
        Flickable {
            Layout.fillWidth: root.bottom
            Layout.preferredWidth: root.bottom ? 700 : topRow.width
            Layout.fillHeight: true
            clip: true
            contentWidth: topRow.width; contentHeight: height
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
            Row {
                id: topRow
                height: parent.height; spacing: 5
                Repeater {
                    model: root.bottom ? (root.assets.launchers || []) : (root.assets.topLaunchers || [])
                    ClassicButton {
                        required property var modelData
                        width: root.bottom ? 34 : 25; height: topRow.height
                        label: modelData.name; icon: modelData.icon || "application-x-executable"
                        available: !!modelData.command && modelData.command.length > 0
                        onClicked: root.run(modelData)
                    }
                }
            }
        }
        ClassicButton {
            visible: root.bottom
            label: "Screenshot"; icon: "applets-screenshooter"
            Layout.preferredWidth: 34; Layout.fillHeight: true
            onClicked: root.run({command: ["hyprshot", "-m", "region"]})
        }
        Repeater {
            model: root.bottom ? ["★", "✮", "✰", "✪"] : []
            ClassicButton {
                required property string modelData
                required property int index
                label: modelData
                Layout.preferredWidth: 25; Layout.fillHeight: true
                selected: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === index + 1
                onClicked: if (!context.locked) Hyprland.dispatch("workspace " + (index + 1))
            }
        }
        ClassicButton {
            visible: root.bottom
            label: "Window controls"; icon: "preferences-system-windows"
            Layout.preferredWidth: 32; Layout.fillHeight: true
            onClicked: if (!context.locked && context.settings.openControls) context.settings.openControls()
        }
    }
}
