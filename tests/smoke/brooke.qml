import QtQuick
import Quickshell

// Run with qs, not qmllint: WidgetHost loads these types dynamically, so linting
// the entrypoint alone does not prove that either panel can be instantiated.
ShellRoot {
    id: root
    property var panels: []
    Item { id: host; width: 1280; height: 41 }
    Component.onCompleted: {
        const component = Qt.createComponent("../../modules/shell/widgets/brooke-panel/Widget.qml", Component.PreferSynchronous)
        if (component.status !== Component.Ready) {
            console.error("BROOKE_SMOKE_FAILED", component.errorString())
            Qt.quit()
            return
        }
        for (const position of ["top", "bottom"]) {
            const panel = component.createObject(host, {
                width: 1280, height: position === "top" ? 25 : 37,
                context: {
                    variant: "compact", locked: false,
                    settings: { position: position, assets: { launchers: [], topLaunchers: [] } },
                    allows: function() { return false }, request: function() { return false }
                }
            })
            if (!panel || panel.isBottom !== (position === "bottom")) {
                console.error("BROOKE_SMOKE_FAILED", position, component.errorString())
                Qt.quit()
                return
            }
            root.panels.push(panel)
        }
        settle.start()
    }
    Timer {
        id: settle
        interval: 500
        onTriggered: {
            console.info("BROOKE_SMOKE_OK: top and bottom panel objects created")
            Qt.quit()
        }
    }
}
