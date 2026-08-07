import QtQuick
import Quickshell
import Quickshell.Io
// This fixture is copied verbatim to modules/shell/task-4-dock-smoke.qml for
// the disposable run so QuickShell resolves the repository's local modules.
import "core" as Core
import "services" as Services
import "surfaces/desktop"

ShellRoot {
    Binding {
        target: Core.InteractiveShellController
        property: "locked"
        value: Services.LockStateService.locked
    }

    IpcHandler {
        target: "dock"

        function open(): bool { return Core.InteractiveShellController.dock("open") }
        function close(): bool { return Core.InteractiveShellController.dock("close") }
        function toggle(): bool { return Core.InteractiveShellController.dock("toggle") }
    }

    TaskDockSurface {}
}
