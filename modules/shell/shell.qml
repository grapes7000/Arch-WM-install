import Quickshell
import "surfaces/bar"
import "surfaces/desktop"

ShellRoot {
    BarSurface {}
    DesktopSurface {}

    // The custom Quickshell lock surface remains intentionally disabled.
    // Hyprlock is the verified authentication boundary for the VM milestone.
}
