import QtQuick
import Quickshell
import Quickshell.Io
import "core" as Core
import "services" as Services
import "surfaces/bar"
import "surfaces/desktop"
import "surfaces/homepage"

ShellRoot {
    Binding {
        target: Core.InteractiveShellController
        property: "locked"
        value: Services.LockStateService.locked
    }

    IpcHandler {
        target: "launcher"

        function open(): bool { return Core.InteractiveShellController.launcher("open") }
        function close(): bool { return Core.InteractiveShellController.launcher("close") }
        function toggle(): bool { return Core.InteractiveShellController.launcher("toggle") }
    }

    IpcHandler {
        target: "drawers"

        function open(kind: string): bool {
            return Core.InteractiveShellController.drawersOpen(kind, "")
        }
        function close(): bool { return Core.InteractiveShellController.drawersClose() }
    }

    IpcHandler {
        target: "dock"

        function open(): bool { return Core.InteractiveShellController.dock("open") }
        function close(): bool { return Core.InteractiveShellController.dock("close") }
        function toggle(): bool { return Core.InteractiveShellController.dock("toggle") }
    }

    BarSurface {}
    HomepageSurface {}
    DesktopSurface {}
    TaskDockSurface {}

    // The custom Quickshell lock surface remains intentionally disabled.
    // Hyprlock is the verified authentication boundary for the VM milestone.
}
