pragma Singleton

import QtQml

QtObject {
    readonly property var policies: ({
        bar: {
            capabilities: [
                "media.control",
                "audio.control",
                "workspace.switch",
                "launcher.open",
                "drawer.open",
                "session.lock",
                "notification.dismiss"
            ]
        },
        desktop: {
            capabilities: [
                "media.control",
                "audio.control",
                "workspace.switch",
                "launcher.open",
                "session.lock",
                "notification.dismiss"
            ]
        },
        lockscreen: {
            capabilities: ["media.control", "audio.control"]
        }
    })

    function capabilities(surface) {
        const policy = policies[surface]
        return policy ? policy.capabilities : []
    }

    function grant(surface, requested) {
        const allowed = capabilities(surface)
        return (requested || []).filter(capability => allowed.indexOf(capability) !== -1)
    }

    function request(surface, granted, locked, handler, capability, payload) {
        if (locked || grant(surface, granted).indexOf(capability) === -1)
            return false
        if (typeof handler !== "function")
            return false
        return handler(capability, payload) === true
    }
}
