import QtQuick
import Quickshell
import "modules/shell/core" as Core
import "modules/shell/services" as Services

ShellRoot {
    id: testRoot

    Component {
        id: contextFactory

        Core.WidgetContext {
            surface: "bar"
            instanceId: "test-widget"
        }
    }

    function fail(message) {
        console.error("CONTROL_PLANE_FAIL:", message)
        Qt.quit()
    }

    function runContract() {
        let calls = 0
        const context = contextFactory.createObject(null, {
            capabilities: ["drawer.open"],
            requestHandler: function(capability, payload) {
                calls += 1
                return capability === "drawer.open" && payload.kind === "audio"
            }
        })
        if (!context.request("drawer.open", { kind: "audio" }))
            return fail("granted host request was rejected")
        if (context.request("drawer.open", { kind: "network" }))
            return fail("host rejection was discarded")
        if (context.request("session.poweroff", {}))
            return fail("undeclared capability reached the host")
        if (calls !== 2)
            return fail("undeclared request invoked the host")
        context.destroy()

        const requested = ["drawer.open"]
        if (Core.SurfaceRegistry.grant("bar", requested).length !== 1)
            return fail("bar did not receive drawer capability")
        if (Core.SurfaceRegistry.grant("desktop", requested).length !== 0)
            return fail("desktop received drawer capability")
        if (Core.SurfaceRegistry.grant("lockscreen", requested).length !== 0)
            return fail("lockscreen received drawer capability")

        Services.LockStateService.locked = true
        if (Services.LockStateService.applyLockedHint("malformed"))
            return fail("malformed LockedHint was accepted")
        if (!Services.LockStateService.locked)
            return fail("malformed LockedHint unlocked the shell")
        if (!Services.LockStateService.applyLockedHint("no"))
            return fail("valid unlocked hint was rejected")
        if (Services.LockStateService.locked)
            return fail("valid unlocked hint was not applied")

        Core.InteractiveShellController.locked = true
        if (Core.InteractiveShellController.drawersOpen("invalid", ""))
            return fail("invalid drawer kind was accepted")
        if (Core.InteractiveShellController.launcher("open"))
            return fail("locked launcher call was accepted")
        if (Core.InteractiveShellController.dock("open"))
            return fail("locked dock call was accepted")

        console.info("CONTROL_PLANE_PASS")
        Qt.quit()
    }

    Timer {
        interval: 0
        running: true
        onTriggered: testRoot.runContract()
    }
}
