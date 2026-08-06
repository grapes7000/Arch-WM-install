import QtQuick 2.15
import QtTest 1.3
import "../../modules/shell/surfaces/desktop"

TestCase {
    name: "DockModel"

    Component {
        id: dockModelComponent

        DockModel {}
    }

    function test_filters_and_groups_windows_by_monitor() {
        const model = createTemporaryObject(dockModelComponent, this, {
            monitorName: "DP-1",
            desktopEntries: [
                { id: "org.kde.konsole.desktop", startupClass: "Konsole", name: "Konsole", icon: "konsole" },
                { id: "org.mozilla.firefox.desktop", startupClass: "firefox", name: "Firefox", icon: "firefox" }
            ],
            sourceToplevels: [
                fakeWindow("0x1", "DP-1", "konsole", "Terminal one", "1"),
                fakeWindow("0x2", "DP-1", "Konsole", "Terminal two", "4"),
                fakeWindow("0x3", "DP-1", "firefox", "Browser", "2"),
                fakeWindow("0x4", "HDMI-A-1", "konsole", "Remote terminal", "3")
            ]
        })

        verify(model)
        compare(model.groups.length, 2)
        compare(model.groups[0].windows.length + model.groups[1].windows.length, 3)
        const terminalGroup = model.groups.find(group => group.name === "Konsole")
        verify(terminalGroup)
        compare(terminalGroup.windows.length, 2)
        compare(terminalGroup.windows[0].workspace.name, "1")
    }

    function test_malformed_identity_uses_address_and_stale_rows_are_removed() {
        const model = createTemporaryObject(dockModelComponent, this, {
            monitorName: "DP-1",
            desktopEntries: [],
            sourceToplevels: [
                fakeWindow("0xbeef", "DP-1", "", "Untitled", "1"),
                fakeWindow("0xdead", "DP-1", "", "Stale", "1", false),
                { address: "", monitor: { name: "DP-1" }, lastIpcObject: { mapped: true } }
            ]
        })

        compare(model.groups.length, 1)
        compare(model.groups[0].key, "address:0xbeef")
        compare(model.groups[0].windows.length, 1)
    }

    function fakeWindow(address, monitor, appClass, title, workspace, mapped) {
        return {
            address,
            title,
            monitor: { name: monitor },
            workspace: { name: workspace },
            activated: false,
            urgent: false,
            lastIpcObject: {
                mapped: mapped === undefined ? true : mapped,
                class: appClass,
                initialClass: appClass
            }
        }
    }
}
