import QtQml
import QtQuick

QtObject {
    id: root

    property string monitorName: ""
    property var sourceToplevels: []
    property var desktopEntries: []
    property var favoriteIds: []
    property var groups: []

    // Changing workspace does not touch the toplevel list or any toplevel
    // property, so the dock needs an explicit signal to re-evaluate which
    // window is visible and focused. Bound by the host to Hyprland's focused
    // workspace purely as a change trigger; the per-window test below uses
    // each window's own monitor so multi-monitor setups stay correct.
    property var focusedWorkspace: null

    readonly property int settleIntervalMs: 120
    readonly property int maxSettleAttempts: 40
    property int settleAttempts: 0
    property bool sawFocusEvent: false

    // Hyprland's toplevel list is live and can still be mid-mutation
    // (partway through applying a batched IPC update) when its change
    // signal fires. Rebuilding groups synchronously in that same call
    // stack raced Quickshell's native property-update-group bookkeeping
    // and produced a reproducible native crash on startup. Deferring the
    // rebuild to the next event-loop tick lets the native update finish
    // first, so this only ever reads a settled toplevel list.
    onSourceToplevelsChanged: restartSettle()
    onDesktopEntriesChanged: rebuildTimer.restart()
    onFavoriteIdsChanged: rebuildTimer.restart()
    onMonitorNameChanged: rebuildTimer.restart()
    onFocusedWorkspaceChanged: rebuildTimer.restart()
    Component.onCompleted: restartSettle()

    property Timer rebuildTimer: Timer {
        interval: 0
        onTriggered: root.rebuild()
    }

    // Quickshell publishes a HyprlandToplevel the moment the window enters
    // the toplevel list, then fills in `monitor`, `lastIpcObject` and the
    // focus flags asynchronously a few hundred milliseconds later. A rebuild
    // driven only by list membership therefore reads bare objects whose
    // monitor is still null, rejects every window, and leaves the dock
    // permanently stuck with no running apps. This timer re-checks until
    // every toplevel has resolved placement.
    property Timer settleTimer: Timer {
        interval: root.settleIntervalMs
        onTriggered: root.rebuild()
    }

    property Connections sourceModelConnections: Connections {
        target: root.sourceToplevels
        ignoreUnknownSignals: true
        function onValuesChanged() { root.restartSettle() }
    }

    // Late-arriving toplevel data (and later focus/urgency changes) never
    // touch the list itself, so the list-level signal above cannot see them.
    property Instantiator toplevelWatcher: Instantiator {
        model: root.sourceToplevels
        delegate: QtObject {
            required property var modelData
            readonly property var watched: modelData
            property Connections toplevelConnections: Connections {
                target: watched
                ignoreUnknownSignals: true
                function onMonitorChanged() { root.restartSettle() }
                function onLastIpcObjectChanged() { root.restartSettle() }
                function onActivatedChanged() { root.rebuildTimer.restart() }
                function onUrgentChanged() { root.rebuildTimer.restart() }
                function onWorkspaceChanged() { root.rebuildTimer.restart() }
            }
        }
    }

    function restartSettle() {
        settleAttempts = 0
        rebuildTimer.restart()
    }

    function isPlacementResolved(window) {
        return !!(window && window.monitor)
    }

    function hasPendingPlacement(toplevels) {
        for (const window of toplevels) {
            if (!isPlacementResolved(window))
                return true
        }
        return false
    }

    function rebuild() {
        const toplevels = valuesOf(sourceToplevels)

        // Quickshell only learns focus from Hyprland's live event stream, so
        // right after startup every toplevel reports activated === false. The
        // `clients` snapshot carries focus order, so use it until the first
        // real focus event arrives. This has to latch: the snapshot goes stale
        // the moment focus moves, and falling back to it again later (for
        // example on an empty workspace, where nothing is activated) would
        // resurrect a long-dead focus and mark a hidden window as focused.
        if (!sawFocusEvent) {
            for (const window of toplevels) {
                if (window && window.activated === true) {
                    sawFocusEvent = true
                    break
                }
            }
        }

        groups = buildGroups(toplevels,
                             valuesOf(desktopEntries),
                             monitorName,
                             favoriteIds,
                             !sawFocusEvent)

        if (!hasPendingPlacement(toplevels)) {
            settleAttempts = 0
            return
        }
        if (settleAttempts >= maxSettleAttempts)
            return
        settleAttempts++
        settleTimer.restart()
    }

    function valuesOf(model) {
        if (!model)
            return []
        return model.values === undefined || typeof model.values === "function"
            ? model : model.values
    }

    function normalize(value) {
        return String(value || "").toLowerCase()
            .replace(/\.desktop$/, "")
            .replace(/[^a-z0-9]/g, "")
    }

    function firstIdentity(window) {
        const ipc = window && window.lastIpcObject ? window.lastIpcObject : ({})
        const waylandId = window && window.wayland ? window.wayland.appId : ""
        const candidates = [ipc.class, ipc.initialClass, waylandId]
        for (const candidate of candidates) {
            if (normalize(candidate).length > 0)
                return String(candidate)
        }
        return ""
    }

    function entryFor(identity, entries) {
        const identityKey = normalize(identity)
        if (!identityKey)
            return null

        for (const entry of entries) {
            if (normalize(entry.startupClass) === identityKey)
                return entry
        }
        for (const entry of entries) {
            if (normalize(entry.id) === identityKey)
                return entry
        }
        return null
    }

    function entryForId(desktopId, entries) {
        for (const entry of entries) {
            if (entry.id === desktopId)
                return entry
        }
        return null
    }

    function identityForEntry(entry) {
        const startupKey = normalize(entry ? entry.startupClass : "")
        if (startupKey)
            return { key: "startup:" + startupKey, entry }
        const entryKey = normalize(entry ? entry.id : "")
        return entryKey ? { key: "entry:" + entryKey, entry } : null
    }

    function windowMonitorName(window) {
        if (!window || !window.monitor)
            return ""
        return String(window.monitor.name || "")
    }

    function isMappedOnMonitor(window, targetMonitor) {
        if (!window || !window.address || !targetMonitor)
            return false
        const ipc = window.lastIpcObject || ({})
        if (ipc.mapped === false)
            return false
        return windowMonitorName(window) === targetMonitor
    }

    function isFocused(window, useSnapshotFocus) {
        if (!window || !isOnActiveWorkspace(window))
            return false
        if (!useSnapshotFocus)
            return window.activated === true
        const ipc = window.lastIpcObject || ({})
        return ipc.focusHistoryID === 0
    }

    // A window that lives on a workspace the monitor is not currently showing
    // is never the focused window, no matter what the focus flags say. This
    // also keeps the dock honest when the user switches to an empty workspace,
    // where Hyprland reports no activated toplevel at all.
    function isOnActiveWorkspace(window) {
        if (!window || !window.workspace || !window.monitor)
            return false
        const workspaceId = window.workspace.id
        const activeWorkspace = window.monitor.activeWorkspace
        if (activeWorkspace && workspaceId === activeWorkspace.id)
            return true
        // Special (scratchpad) workspaces overlay the monitor's normal
        // workspace, so they are visible without ever being the monitor's
        // active workspace.
        return !!(focusedWorkspace && focusedWorkspace.id === workspaceId)
    }

    function identityFor(window, entries) {
        const appIdentity = firstIdentity(window)
        const entry = entryFor(appIdentity, entries)
        const startupKey = entry ? normalize(entry.startupClass) : ""
        if (startupKey)
            return { key: "startup:" + startupKey, entry, appIdentity }
        const entryKey = entry ? normalize(entry.id) : ""
        if (entryKey)
            return { key: "entry:" + entryKey, entry, appIdentity }
        const appKey = normalize(appIdentity)
        if (appKey)
            return { key: "app:" + appKey, entry: null, appIdentity }
        return {
            key: "address:" + String(window.address),
            entry: null,
            appIdentity: "Application"
        }
    }

    function buildGroups(toplevels, entries, targetMonitor, favorites, useSnapshotFocus) {
        const byKey = ({})
        for (const window of toplevels) {
            if (!isMappedOnMonitor(window, targetMonitor))
                continue

            const identity = identityFor(window, entries)
            let group = byKey[identity.key]
            if (!group) {
                group = {
                    key: identity.key,
                    name: identity.entry && identity.entry.name
                        ? identity.entry.name : identity.appIdentity,
                    icon: identity.entry && identity.entry.icon
                        ? identity.entry.icon : "application-x-executable",
                    desktopId: identity.entry ? identity.entry.id : "",
                    pinned: false,
                    running: true,
                    windows: [],
                    active: false,
                    urgent: false
                }
                byKey[identity.key] = group
            }
            group.windows.push(window)
            group.active = group.active || isFocused(window, useSnapshotFocus)
            group.urgent = group.urgent || window.urgent === true
        }

        const favoriteList = Array.isArray(favorites) ? favorites : []
        for (const desktopId of favoriteList) {
            const entry = entryForId(desktopId, entries)
            const identity = identityForEntry(entry)
            if (!identity)
                continue
            let group = byKey[identity.key]
            if (!group) {
                group = {
                    key: identity.key,
                    name: entry.name || desktopId,
                    icon: entry.icon || "application-x-executable",
                    desktopId,
                    pinned: true,
                    running: false,
                    windows: [],
                    active: false,
                    urgent: false
                }
                byKey[identity.key] = group
            } else {
                group.desktopId = desktopId
                group.pinned = true
            }
        }

        const result = []
        for (const key in byKey)
            result.push(byKey[key])
        result.sort((left, right) => {
            if (left.pinned && right.pinned)
                return favoriteList.indexOf(left.desktopId) - favoriteList.indexOf(right.desktopId)
            if (left.pinned !== right.pinned)
                return left.pinned ? -1 : 1
            return left.name.localeCompare(right.name)
        })
        return result
    }
}
