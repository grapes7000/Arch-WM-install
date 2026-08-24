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
    readonly property string path: configHome + "/theme-engine/generated/ui-style.json"

    property var data: ({
        schema_version: 1,
        name: "precision",
        metrics: {
            grid: 4,
            spacing_xs: 4,
            spacing_sm: 8,
            spacing_md: 12,
            spacing_lg: 16,
            spacing_xl: 20,
            spacing_2xl: 24,
            spacing_3xl: 32,
            page_padding: 20,
            page_padding_compact: 16,
            section_gap: 20,
            control_height_compact: 24,
            control_height: 30,
            control_height_large: 36,
            sidebar_width: 190,
            icon_size: 14,
            icon_box: 16,
            radius_control: 3,
            radius_surface: 4,
            radius_overlay: 8,
            border_width: 1,
            focus_width: 1,
            font_caption: 11,
            font_secondary: 12,
            font_body: 13,
            font_section: 13,
            font_title: 16
        },
        patterns: {
            surface: "flat",
            section: "divider",
            list_row: "flat",
            selection: "accent-soft-marker",
            button: "quiet",
            field: "outlined",
            dialog: "elevated",
            status: "semantic-muted",
            shadow: "overlay-only",
            motion: "restrained"
        }
    })

    readonly property var metrics: data.metrics || ({})
    readonly property var patterns: data.patterns || ({})
    readonly property string name: data.name || "precision"

    function metric(name, fallback) {
        const value = metrics[name]
        return value === undefined ? fallback : Number(value)
    }

    readonly property int grid: metric("grid", 4)
    readonly property int spacingXs: metric("spacing_xs", 4)
    readonly property int spacingSm: metric("spacing_sm", 8)
    readonly property int spacingMd: metric("spacing_md", 12)
    readonly property int spacingLg: metric("spacing_lg", 16)
    readonly property int spacingXl: metric("spacing_xl", 20)
    readonly property int spacing2xl: metric("spacing_2xl", 24)
    readonly property int spacing3xl: metric("spacing_3xl", 32)
    readonly property int controlHeightCompact: metric("control_height_compact", 24)
    readonly property int controlHeight: metric("control_height", 30)
    readonly property int controlHeightLarge: metric("control_height_large", 36)
    readonly property int iconSize: metric("icon_size", 14)
    readonly property int iconBox: metric("icon_box", 16)
    readonly property int radiusControl: metric("radius_control", 3)
    readonly property int radiusSurface: metric("radius_surface", 4)
    readonly property int radiusOverlay: metric("radius_overlay", 8)
    readonly property int borderWidth: metric("border_width", 1)
    readonly property int focusWidth: metric("focus_width", 1)
    readonly property int fontCaption: metric("font_caption", 11)
    readonly property int fontSecondary: metric("font_secondary", 12)
    readonly property int fontBody: metric("font_body", 13)
    readonly property int fontSection: metric("font_section", 13)
    readonly property int fontTitle: metric("font_title", 16)

    readonly property bool flatSurfaces: patterns.surface === "flat"
    readonly property bool dividerSections: patterns.section === "divider"
    readonly property bool flatRows: patterns.list_row === "flat"
    readonly property bool quietButtons: patterns.button === "quiet"
    readonly property bool accentMarkerSelection: patterns.selection === "accent-soft-marker"
    readonly property bool overlayOnlyShadows: patterns.shadow === "overlay-only"

    // Motion is semantic too. Shell components consume these values rather
    // than inferring animation personality from button/surface geometry.
    readonly property string motion: patterns.motion || (quietButtons ? "restrained" : "playful")
    readonly property bool motionNone: motion === "none"
    readonly property bool motionRestrained: motion === "restrained"
    readonly property bool motionPlayful: motion === "playful"
    readonly property int motionFastMs: motionNone ? 0 : (motionRestrained ? 90 : 140)
    readonly property int motionNormalMs: motionNone ? 0 : (motionRestrained ? 120 : 180)
    readonly property real hoverScale: motionNone ? 1.0 : (motionRestrained ? 1.025 : 1.10)
    readonly property real hoverLift: motionNone ? 0.0 : (motionRestrained ? 0.0 : -2.0)
    readonly property real selectedPulse: motionNone ? 1.0 : (motionRestrained ? 1.035 : 1.18)
    readonly property real pressScale: motionNone ? 1.0 : (motionRestrained ? 0.99 : 0.97)
    readonly property real releaseOvershoot: motionPlayful ? 1.45 : 0.0

    function parse(contents) {
        if (!contents || typeof contents !== "string" || contents.length === 0)
            return
        try {
            const parsed = JSON.parse(contents)
            if (parsed.schema_version !== 1 || !parsed.metrics || !parsed.patterns)
                throw new Error("invalid UI style contract")
            root.data = parsed
        } catch (error) {
            console.warn("UI style update rejected; keeping last known-good style:", error)
        }
    }

    FileView {
        id: styleFile
        path: root.path
        blockLoading: true
        watchChanges: true
        onTextChanged: root.parse(styleFile.text())
        onFileChanged: styleFile.reload()
    }

    Component.onCompleted: root.parse(styleFile.text())
}
