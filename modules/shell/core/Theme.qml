pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property string path: Quickshell.env("HOME")
        + "/.config/theme-engine/generated/theme.json"

    property var data: ({
        roles: {
            bg: "#0a0a0f",
            bg_alt: "#15121a",
            text: "#ff6ec7",
            text_dim: "#c86fa6",
            accent: "#00e5ff",
            accent2: "#ff1493",
            urgent: "#ff0055"
        },
        style: {
            corner_radius: 0,
            gaps: 4,
            border_width: 2
        }
    })

    readonly property var roles: data.roles || ({})
    readonly property var style: data.style || ({})

    function parse(contents) {
        if (!contents || contents.trim().length === 0)
            return

        try {
            const parsed = JSON.parse(contents)
            if (!parsed.roles || !parsed.style)
                throw new Error("theme requires roles and style")
            root.data = parsed
        } catch (error) {
            console.warn("Theme update rejected; keeping last known-good theme:", error)
        }
    }

    FileView {
        id: themeFile
        path: root.path
        blockLoading: true
        watchChanges: true
        onTextChanged: root.parse(text)
        onFileChanged: reload()
    }

    Component.onCompleted: root.parse(themeFile.text)
}
