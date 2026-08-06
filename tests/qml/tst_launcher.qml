import QtQuick
import QtTest
import "../../modules/shell/surfaces/bar"

TestCase {
    name: "LauncherBehavior"

    LauncherSession {
        id: session
    }

    function init() {
        session.locked = false
        session.close()
    }

    function test_session_open_close_and_lock_denial() {
        const screen = { name: "fixture-screen" }

        compare(session.open(screen), true)
        compare(session.visible, true)
        compare(session.screen.name, "fixture-screen")
        compare(session.toggle(screen), true)
        compare(session.visible, false)

        session.locked = true
        compare(session.open(screen), false)
        compare(session.visible, false)
    }

}
