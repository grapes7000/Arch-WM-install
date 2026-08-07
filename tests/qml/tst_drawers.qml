import QtQuick
import QtTest
import "../../modules/shell/surfaces/bar"

TestCase {
    name: "DrawerBehavior"

    DrawerController {
        id: controller
    }

    function init() {
        controller.locked = false
        controller.close()
    }

    function test_open_replaces_active_drawer_and_close_clears_state() {
        const screen = { name: "DP-1" }
        const audioAnchor = { objectName: "audio-anchor" }
        const networkAnchor = { objectName: "network-anchor" }

        compare(controller.open("audio", audioAnchor, screen), true)
        compare(controller.activeKind, "audio")
        compare(controller.anchorItem, audioAnchor)
        compare(controller.screen, screen)

        compare(controller.open("network", networkAnchor, screen), true)
        compare(controller.activeKind, "network")
        compare(controller.anchorItem, networkAnchor)
        compare(controller.visible, true)

        compare(controller.close(), true)
        compare(controller.activeKind, "")
        compare(controller.anchorItem, null)
        compare(controller.screen, null)
        compare(controller.visible, false)
    }

    function test_invalid_and_locked_open_are_rejected_without_stale_state() {
        const screen = { name: "DP-1" }

        compare(controller.open("invalid", null, screen), false)
        compare(controller.visible, false)

        compare(controller.open("audio", null, screen), true)
        controller.locked = true
        compare(controller.visible, false)
        compare(controller.activeKind, "")
        compare(controller.open("network", null, screen), false)
    }

}
