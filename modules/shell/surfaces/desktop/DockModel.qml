import QtQml

QtObject {
    id: root

    property string monitorName: ""
    property var sourceToplevels: []
    property var desktopEntries: []
    readonly property var groups: buildGroups(valuesOf(sourceToplevels),
                                               valuesOf(desktopEntries),
                                               monitorName)

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

    function buildGroups(toplevels, entries, targetMonitor) {
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
                    windows: [],
                    active: false,
                    urgent: false
                }
                byKey[identity.key] = group
            }
            group.windows.push(window)
            group.active = group.active || window.activated === true
            group.urgent = group.urgent || window.urgent === true
        }

        const result = []
        for (const key in byKey)
            result.push(byKey[key])
        result.sort((left, right) => left.name.localeCompare(right.name))
        return result
    }
}
