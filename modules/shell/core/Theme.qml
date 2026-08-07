pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configHome: {
        const configured = Quickshell.env("XDG_CONFIG_HOME")
        return configured || (Quickshell.env("HOME") + "/.config")
    }
    readonly property string path: configHome + "/theme-engine/generated/theme.json"
    readonly property string homepageImagesDir: configHome + "/quickshell/homepage-images"

    property var homepageImages: []
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
            corner_radius: 10,
            gaps: 8,
            border_width: 2,
            bar_height: 48,
            animation_ms: 160,
            animation_profile: "smooth",
            workspace_animation: "slide",
            motion_scale: 1.0,
            surface_opacity: 0.72,
            opacity: 1.0,
            opacity_inactive: 0.96,
            blur_on: true,
            blur_strength: 6,
            blur_passes: 2,
            shadow_on: true,
            shadow_radius: 20
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
    readonly property int radius: style.corner_radius === undefined ? 10 : style.corner_radius
    readonly property int gap: style.gaps === undefined ? 8 : style.gaps
    readonly property int borderWidth: style.border_width === undefined ? 2 : style.border_width
    readonly property int barHeight: style.bar_height === undefined ? 48 : style.bar_height
    readonly property int animationMs: style.animation_ms === undefined ? 160 : style.animation_ms
<<<<<<< Updated upstream
    readonly property string animationProfile: style.animation_profile || "smooth"
    readonly property string workspaceAnimation: style.workspace_animation || "slide"
    readonly property real motionScale: style.motion_scale === undefined ? 1.0 : Math.max(0, Math.min(2, Number(style.motion_scale)))
    readonly property real surfaceOpacity: style.surface_opacity === undefined ? 0.72 : Math.max(0, Math.min(1, Number(style.surface_opacity)))
    readonly property bool blurEnabled: style.blur_on === undefined ? true : Boolean(style.blur_on)
    readonly property int blurStrength: style.blur_strength === undefined ? 6 : Math.max(1, Number(style.blur_strength))
    readonly property int blurPasses: style.blur_passes === undefined ? 2 : Math.max(1, Number(style.blur_passes))
    readonly property bool shadowEnabled: style.shadow_on === undefined ? true : Boolean(style.shadow_on)
    readonly property int shadowRadius: style.shadow_radius === undefined ? 20 : Math.max(0, Number(style.shadow_radius))

    function applyHomepageImages(baseData) {
        const merged = Object.assign({}, baseData || root.data)
        merged.wallpapers = root.homepageImages.slice()
        root.data = merged
    }
=======
    // Shell typography is intentionally stable across theme changes. Theme data
    // controls visual tokens, while this shared provider keeps every shell
    // surface and widget on JetBrainsMono Nerd Font. Qt registers this font
    // under the canonical installed family name below.
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
>>>>>>> Stashed changes

    function parse(contents) {
        if (!contents || typeof contents !== "string" || contents.length === 0)
            return

        try {
            const parsed = JSON.parse(contents)
            if (parsed.schema_version !== 1)
                throw new Error("unsupported theme schema")
            if (!parsed.roles || !parsed.style)
                throw new Error("theme requires roles and style")
            applyHomepageImages(parsed)
        } catch (error) {
            console.warn("Theme update rejected; keeping last known-good theme:", error)
        }
    }

    function refreshHomepageImages() {
        if (!homepageImagesProcess.running)
            homepageImagesProcess.running = true
    }

    Process {
        id: homepageImagesProcess
        command: [
            "sh", "-c",
            "dir=\"$1\"; mkdir -p \"$dir\"; "
            + "find \"$dir\" -maxdepth 1 -type f \\( "
            + "-iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o "
            + "-iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \\) "
            + "-print | LC_ALL=C sort",
            "sh", root.homepageImagesDir
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const images = text.split("\n").map(path => path.trim()).filter(path => path.length > 0)
                root.homepageImages = images
                root.applyHomepageImages(root.data)
            }
        }
    }

    FileView {
        id: themeFile
        path: root.path
        blockLoading: true
        watchChanges: true
        onTextChanged: root.parse(themeFile.text())
        onFileChanged: themeFile.reload()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshHomepageImages()
    }

    Component.onCompleted: {
        root.parse(themeFile.text())
        root.refreshHomepageImages()
    }
}
