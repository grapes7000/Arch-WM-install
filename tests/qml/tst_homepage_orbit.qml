import QtQuick
import QtTest
import "../../modules/shell/surfaces/homepage" as Homepage

TestCase {
    id: testCase
    name: "HomepageOrbit"
    when: windowShown
    width: 520
    height: 320

    Component {
        id: toggleComponent
        Homepage.SectionToggle {
            icon: "󰍛"
            label: "System"
        }
    }

    Component {
        id: shortcutComponent
        Homepage.FloatingAppShortcut {
            label: "Terminal"
            fallbackIcon: "󰆍"
        }
    }

    SignalSpy {
        id: activationSpy
        signalName: "activated"
    }

    function test_section_toggle_exposes_active_state_and_activation() {
        const toggle = createTemporaryObject(toggleComponent, testCase, {
            x: 20,
            y: 20,
            width: 96,
            height: 64,
            active: true
        })
        verify(toggle !== null)
        compare(toggle.active, true)

        activationSpy.target = toggle
        mouseClick(toggle, toggle.width / 2, toggle.height / 2, Qt.LeftButton)
        compare(activationSpy.count, 1)
        activationSpy.clear()
    }

    function test_floating_shortcut_is_uncontained_and_activates() {
        const shortcut = createTemporaryObject(shortcutComponent, testCase, {
            x: 140,
            y: 20,
            width: 84,
            height: 84
        })
        verify(shortcut !== null)
        compare(shortcut.label, "Terminal")

        activationSpy.target = shortcut
        mouseClick(shortcut, shortcut.width / 2, shortcut.height / 2, Qt.LeftButton)
        compare(activationSpy.count, 1)
        activationSpy.clear()
    }

    function test_system_stage_accepts_shared_history() {
        const component = Qt.createComponent(
            "../../modules/shell/surfaces/homepage/SystemOverviewStage.qml")
        compare(component.status, Component.Ready, component.errorString())
        const stage = createTemporaryObject(component, testCase, {
            width: 480,
            height: 240,
            cpuHistory: [10, 20, 30],
            memoryHistory: [30, 35, 40]
        })
        verify(stage !== null)
        compare(stage.cpuHistory.length, 3)
        compare(stage.memoryHistory[2], 40)
    }
}
