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
            surface_0: "#12151a",
            surface_1: "#181c23",
            surface_2: "#202630",
            overlay: "#262d38",
            hover: "#2c3441",
            selected: "#4f8cff",
            text: "#f4f7fb",
            text_dim: "#8b95a5",
            focus: "#4f8cff",
            border_normal: "#272c35",
            border_subtle: "#262c35",
            border_strong: "#4f8cff",
            accent: "#4f8cff",
            accent2: "#8b5cf6",
            urgent: "#ff4d6d"
        },
        style: {
            corner_radius: 10,
            gaps: 8,
            window_gap: 8,
            bar_padding: 8,
            border_width: 1,
            bar_height: 48,
            animation_ms: 160,
            animation_profile: "smooth",
            workspace_animation: "slide",
            motion_scale: 1.0,
            surface_opacity: 0.96,
            opacity: 1.0,
            opacity_inactive: 0.96,
            blur_on: true,
            blur_strength: 6,
            blur_passes: 2,
            shadow_on: true,
            shadow_radius: 20,
            shadow_opacity: 0.40,
            shadow_color: "#000000"
        },
        components: {
            homepage: {
                bar_position: "top",
                bar_surface_role: "surface_0",
                bar_opacity: 0.96,
                bar_outline_role: "border_subtle",
                bar_outline_opacity: 0.72,
                drawer_width: 420,
                drawer_surface_role: "surface_1",
                drawer_opacity: 0.97,
                drawer_outline_role: "border_subtle",
                drawer_outline_opacity: 0.76,
                card_opacity: 0.92,
                image_fit: "cover",
                slideshow_seconds: 30,
                image_overlay_opacity: 0.10,
                image_dimming: 0.28,
                transition_ms: 320
            }
        }
    })

    readonly property var roles: data.roles || ({})
    readonly property var style: data.style || ({})
    readonly property var components: data.components || ({})
    readonly property var shellConfig: components.homepage || ({})

    readonly property string background: roles.bg || "#0a0a0f"
    readonly property string surfaceBase: roles.surface_0 || roles.bg_alt || "#15121a"
    readonly property string surfaceRaised: roles.surface_1 || roles.bg_alt || surfaceBase
    readonly property string surfaceElevated: roles.surface_2 || surfaceRaised
    readonly property string surfaceOverlay: roles.overlay || surfaceElevated
    readonly property string surfaceHover: roles.hover || surfaceElevated
    readonly property string selected: roles.selected || roles.accent || "#4f8cff"
    readonly property string surface: surfaceBase
    readonly property string foreground: roles.text || "#f4f7fb"
    readonly property string muted: roles.text_dim || foreground
    readonly property string accent: roles.accent || "#4f8cff"
    readonly property string accent2: roles.accent2 || "#8b5cf6"
    readonly property string urgent: roles.urgent || "#ff4d6d"

    // Application/shell geometry belongs to the UI-style contract. Theme JSON
    // remains the source of semantic color and desktop compositor effects.
    readonly property int radius: UiStyle.radiusSurface
    readonly property int controlRadius: UiStyle.radiusControl
    readonly property int overlayRadius: UiStyle.radiusOverlay
    readonly property int windowGap: style.window_gap === undefined
        ? (style.gaps === undefined ? 8 : Math.max(0, Number(style.gaps)))
        : Math.max(0, Number(style.window_gap))
    readonly property int gap: UiStyle.spacingSm
    readonly property int borderWidth: UiStyle.borderWidth

    function roleColor(roleName, fallback) {
        if (typeof roleName === "string" && roleName.charAt(0) === "#")
            return roleName
        return roles[roleName] || fallback
    }

    function alphaColor(token, alpha) {
        const c = Qt.color(token)
        return Qt.rgba(c.r, c.g, c.b, Math.max(0, Math.min(1, Number(alpha))))
    }

    // Shell room: bar. Metrics are semantic UI-style values, while surface
    // colors and opacity remain palette/theme concerns.
    readonly property string barPosition: shellConfig.bar_position || "top"
    readonly property int barHeight: UiStyle.controlHeightLarge
    readonly property int barPadding: Math.min(
        UiStyle.spacingXs,
        Math.max(0, Math.floor((barHeight - 16) / 2))
    )
    readonly property int barOuterMargin: UiStyle.spacingXs
    readonly property int barRadius: UiStyle.radiusSurface
    readonly property string barSurfaceColor: roleColor(shellConfig.bar_surface_role || "surface_0", surfaceBase)
    readonly property real barOpacity: shellConfig.bar_opacity === undefined
        ? (style.surface_opacity === undefined ? 0.96 : Number(style.surface_opacity))
        : Math.max(0, Math.min(1, Number(shellConfig.bar_opacity)))
    readonly property string barOutlineColor: roleColor(shellConfig.bar_outline_role || "border_subtle", roles.border_subtle || roles.border_normal || accent2)
    readonly property real barOutlineOpacity: shellConfig.bar_outline_opacity === undefined ? 0.72 : Math.max(0, Math.min(1, Number(shellConfig.bar_outline_opacity)))
    readonly property int barOutlineWidth: UiStyle.borderWidth
    readonly property int barWidgetSpacing: UiStyle.spacingXs
    readonly property int barPillMinWidth: Math.max(UiStyle.controlHeightCompact, UiStyle.iconBox + UiStyle.spacingSm)
    readonly property int barIconSize: UiStyle.iconSize
    readonly property int barFontSize: UiStyle.fontCaption

    // Shell room: drawers.
    readonly property int drawerWidth: shellConfig.drawer_width === undefined ? 420 : Math.max(260, Number(shellConfig.drawer_width))
    readonly property int drawerOffset: UiStyle.spacingSm
    readonly property int drawerPadding: UiStyle.spacingMd
    readonly property int drawerRadius: UiStyle.radiusOverlay
    readonly property string drawerSurfaceColor: roleColor(shellConfig.drawer_surface_role || "surface_1", surfaceRaised)
    readonly property real drawerOpacity: shellConfig.drawer_opacity === undefined ? 0.97 : Math.max(0, Math.min(1, Number(shellConfig.drawer_opacity)))
    readonly property string drawerOutlineColor: roleColor(shellConfig.drawer_outline_role || "border_subtle", roles.border_subtle || roles.border_normal || accent2)
    readonly property real drawerOutlineOpacity: shellConfig.drawer_outline_opacity === undefined ? 0.76 : Math.max(0, Math.min(1, Number(shellConfig.drawer_outline_opacity)))
    readonly property int drawerOutlineWidth: UiStyle.borderWidth

    // Shell room: homepage and shared typography.
    readonly property int homepageCardRadius: UiStyle.radiusSurface
    readonly property real homepageCardOpacity: shellConfig.card_opacity === undefined ? 0.92 : Math.max(0, Math.min(1, Number(shellConfig.card_opacity)))
    readonly property string homepageImageFit: shellConfig.image_fit || "cover"
    readonly property int homepageSlideshowSeconds: shellConfig.slideshow_seconds === undefined ? 30 : Math.max(5, Number(shellConfig.slideshow_seconds))
    readonly property real homepageImageOverlayOpacity: shellConfig.image_overlay_opacity === undefined ? 0.10 : Math.max(0, Math.min(0.5, Number(shellConfig.image_overlay_opacity)))
    readonly property real homepageImageDimming: shellConfig.image_dimming === undefined ? 0.28 : Math.max(0, Math.min(0.85, Number(shellConfig.image_dimming)))
    readonly property int homepageTransitionMs: shellConfig.transition_ms === undefined ? 320 : Math.max(0, Number(shellConfig.transition_ms))
    readonly property int shellFontSize: UiStyle.fontBody

    // Motion is deliberately calmer for quiet/precision controls. Desktop
    // animation profiles still own compositor motion outside Quickshell.
    readonly property int animationMs: UiStyle.quietButtons ? 110 : (style.animation_ms === undefined ? 160 : style.animation_ms)
    readonly property string animationProfile: style.animation_profile || "smooth"
    readonly property string workspaceAnimation: style.workspace_animation || "slide"
    readonly property real motionScale: style.motion_scale === undefined ? 1.0 : Math.max(0, Math.min(2, Number(style.motion_scale)))
    readonly property real surfaceOpacity: style.surface_opacity === undefined ? 0.96 : Math.max(0, Math.min(1, Number(style.surface_opacity)))
    readonly property bool blurEnabled: style.blur_on === undefined ? true : Boolean(style.blur_on)
    readonly property int blurStrength: style.blur_strength === undefined ? 6 : Math.max(1, Number(style.blur_strength))
    readonly property int blurPasses: style.blur_passes === undefined ? 2 : Math.max(1, Number(style.blur_passes))
    readonly property bool shadowEnabled: UiStyle.overlayOnlyShadows
        ? true
        : (style.shadow_on === undefined ? true : Boolean(style.shadow_on))
    readonly property int shadowRadius: style.shadow_radius === undefined ? 20 : Math.max(0, Number(style.shadow_radius))
    readonly property real shadowOpacity: style.shadow_opacity === undefined
        ? 0.40 : Math.max(0, Math.min(1, Number(style.shadow_opacity)))
    readonly property string shadowColor: style.shadow_color || roles.shadow || background

    readonly property string fontFamily: "Inter"

    function applyHomepageImages(baseData) {
        const merged = Object.assign({}, baseData || root.data)
        merged.wallpapers = root.homepageImages.slice()
        root.data = merged
    }

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
            + "find -L \"$dir\" -maxdepth 1 -type f \\( "
            + "-iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o "
            + "-iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \\) "
            + "-exec readlink -f -- {} \\; | LC_ALL=C sort",
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
