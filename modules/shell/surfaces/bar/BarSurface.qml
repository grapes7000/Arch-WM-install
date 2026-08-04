import QtQuick
import Quickshell
import "../.."
import "../../core"
import "../../widgets/clock" as Clock

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 44
    color: Theme.roles.bg || "#0a0a0f"

    WidgetContext {
        id: clockContext
        surface: "bar"
        instanceId: "clock-main"
        variant: "compact"
        density: 1.0
        locked: false
        availableWidth: 180
        availableHeight: root.implicitHeight
        capabilities: SurfaceRegistry.capabilities("bar")
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.style.gaps ?? 4
        color: Theme.roles.bg_alt || "#15121a"
        radius: Theme.style.corner_radius ?? 0
        border.width: Theme.style.border_width ?? 2
        border.color: Theme.roles.accent2 || "#ff1493"

        Clock.Widget {
            anchors.centerIn: parent
            context: clockContext
        }
    }
}
