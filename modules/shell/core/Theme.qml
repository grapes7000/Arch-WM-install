pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME")
        + "/.config/theme-engine/generated/theme.json"

    property var data: ({
        schema_version: 1,
        name: "fallback",
        dark: true,
        roles: {
            bg: "#0a0a0f",
            bg_alt: "#15121a",
            text: "#ff6ec7",
            text_dim: "#c86fa6",
            focus: "#ff3cac",
            border_normal: "#ff1493",
            accent: "#00e5ff",
            accent2: "#ff1493",
            urgent: "#ff0055"
        },
        style: {
            corner_radius: 0,
            gaps: 8,
            border_width: 2,
            bar_height: 48,
            animation_ms: 160
        }
    })

    readonly property var roles: data.roles || ({})
    readonly property var style: data.style || ({})
    readonly property string background: roles.bg || "#0a0a0f"
    readonly property string surface: roles.bg_alt || "#15121a"
    readonly property string foreground: roles.text || "#ff6ec7"
    readonly property string muted: roles.text_dim || foreground
    readonly property string accent: roles.accent || "#00e5ff"
    readonly property string accent2: roles.accent2 || "#ff1493"
    readonly property string urgent: roles.urgent || "#ff0055"
    readonly property int radius: style.corner_radius === undefined ? 0 : style.corner_radius
    readonly property int gap: style.gaps === undefined ? 8 : style.gaps
    readonly property int borderWidth: style.border_width === undefined ? 2 : style.border_width
    readonly property int barHeight: style.bar_height === undefined ? 48 : style.bar_height
    readonly property int animationMs: style.animation_ms === undefined ? 160 : style.animation_ms

    function parse(contents) {
        if (typeof contents !== "string" || contents.trim().length === 0)
            return

        try {
            const parsed = JSON.parse(contents)
            if (parsed.schema_version !== 1)
                throw new Error("unsupported theme schema")
            if (!parsed.roles || !parsed.style)
                throw new Error("theme requires roles and style")
            root.data = parsed
        } catch (error) {
            console.warn("Theme update rejected; keeping last known-good theme:", error)
        }
    }

    function reloadTheme() {
        root.parse(themeFile.text())
    }

    FileView {
        id: themeFile
        path: root.path
        blockLoading: true
        watchChanges: true
        onTextChanged: root.reloadTheme()
        onFileChanged: reload()
    }

    Component.onCompleted: root.reloadTheme()
}
