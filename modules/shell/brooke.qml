import QtQuick
import Quickshell
import Quickshell.Io
import "core" as Core
import "services" as Services
import "surfaces/brooke"
import "surfaces/bar"
import "surfaces/osd"
ShellRoot {
    Component.onCompleted: Qt.application.font.family = Core.Theme.fontFamily
    Binding { target: Core.InteractiveShellController; property: "locked"; value: Services.LockStateService.locked }
    IpcHandler {
        target: "launcher"
        function open(): bool { return Core.InteractiveShellController.launcher("open") }
        function close(): bool { return Core.InteractiveShellController.launcher("close") }
        function toggle(): bool { return Core.InteractiveShellController.launcher("toggle") }
    }
    IpcHandler {
        target: "audio"
        function up(): bool { return Services.AudioService.adjustVolume(5) }
        function down(): bool { return Services.AudioService.adjustVolume(-5) }
        function mute(): bool { return Services.AudioService.toggleMute() }
    }
    IpcHandler {
        target: "brightness"
        function up(): bool { return Services.BrightnessService.adjust(5) }
        function down(): bool { return Services.BrightnessService.adjust(-5) }
    }
    LauncherOverlay { bottomLeft: true }
    DrawerSurface {}
    BrookeSurface {}
    OsdSurface {}
}
