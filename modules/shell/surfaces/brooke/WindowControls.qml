import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../services" as Services
import "../../widgets/brooke-panel" as Brooke
PanelWindow {
    id: root
    property var targetScreen
    property bool shown: false
    signal dismiss()
    screen: targetScreen
    visible: shown && !Services.LockStateService.locked
    anchors { right: true; bottom: true }
    margins { right: 4; bottom: 45 }
    implicitWidth: 410; implicitHeight: 73
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    color: "#bfbfbf"
    Text { x: 8; y: 4; text: "Active window controls"; font.pixelSize: 15; color: "black" }
    Row {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 5 }
        spacing: 4
        Repeater {
            model: [
                {name: "Arrange", action: 'hl.dsp.window.float({action = "toggle"})'},
                {name: "Minimize", action: 'hl.dsp.window.move({workspace = "special:brooke-minimized", follow = false})'},
                {name: "Restore", action: 'hl.dsp.workspace.toggle_special("brooke-minimized")'},
                {name: "Maximize", action: 'hl.dsp.window.fullscreen({mode = "maximized", action = "toggle"})'},
                {name: "Close", action: 'hl.dsp.window.close()'}
            ]
            Brooke.ClassicButton {
                required property var modelData
                width: 76; height: 35; label: modelData.name
                onClicked: { if (!Services.LockStateService.locked) Hyprland.dispatch(modelData.action); root.dismiss() }
            }
        }
    }
}
