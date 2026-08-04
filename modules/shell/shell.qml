import Quickshell
import "surfaces/bar"

ShellRoot {
    // The scaffold starts only the bar. Desktop and lock-screen surfaces become
    // layout-driven after the registry and security policy are implemented.
    BarSurface {}
}
