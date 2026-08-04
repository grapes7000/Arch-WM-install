pragma Singleton

import QtQuick

QtObject {
    readonly property var policies: ({
        bar: {
            capabilities: ["media.control", "audio.control", "workspace.switch"]
        },
        desktop: {
            capabilities: ["media.control", "audio.control", "workspace.switch", "launcher.open"]
        },
        lockscreen: {
            capabilities: ["media.control", "audio.control"]
        }
    })

    function capabilities(surface) {
        const policy = policies[surface]
        return policy ? policy.capabilities : []
    }
}
