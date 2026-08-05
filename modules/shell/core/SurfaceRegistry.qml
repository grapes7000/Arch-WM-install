pragma Singleton

import Quickshell

Singleton {
    readonly property var policies: ({
        bar: {
            capabilities: [
                "media.control",
                "audio.control",
                "workspace.switch",
                "launcher.open",
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
}
