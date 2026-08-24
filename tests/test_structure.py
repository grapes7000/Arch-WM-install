from __future__ import annotations

import json
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class StructureTests(unittest.TestCase):
    def test_required_docs_exist(self) -> None:
        for relative in (
            "AGENTS.md",
            "docs/ARCHITECTURE.md",
            "docs/WIDGET-SYSTEM.md",
            "docs/INSTALLER.md",
        ):
            self.assertTrue((ROOT / relative).is_file(), relative)

    def test_no_eww_paths_in_managed_modules(self) -> None:
        for base in (ROOT / "modules", ROOT / "vendor" / "hyprland"):
            for path in base.rglob("*"):
                self.assertNotIn("eww", path.name.lower(), str(path))

    def test_clock_supports_all_surfaces(self) -> None:
        manifest = json.loads(
            (ROOT / "modules/shell/widgets/clock/manifest.json").read_text()
        )
        self.assertEqual(
            set(manifest["surfaces"]), {"bar", "desktop", "lockscreen"}
        )
        self.assertTrue(manifest["lockSafe"])

    def test_fileview_text_is_called_as_a_method(self) -> None:
        readers = {
            "modules/shell/core/Theme.qml": ("themeFile",),
            "modules/shell/core/WidgetRegistry.qml": ("registryFile",),
            "modules/shell/services/LayoutService.qml": ("barFile", "desktopFile"),
        }
        for relative, object_names in readers.items():
            content = (ROOT / relative).read_text(encoding="utf-8")
            for object_name in object_names:
                self.assertIn(f"{object_name}.text()", content, relative)
                self.assertIsNone(
                    re.search(rf"\b{re.escape(object_name)}\.text(?!\s*\()", content),
                    relative,
                )

    def test_widget_context_is_set_during_object_construction(self) -> None:
        content = (
            ROOT / "modules/shell/components/WidgetHost.qml"
        ).read_text(encoding="utf-8")
        self.assertIn(
            "component.createObject(container, { context: widgetContext })",
            content,
        )
        self.assertIn("const container = root.pillEnabled ? pill : root", content)
        self.assertNotIn("item.context = widgetContext", content)
        self.assertNotIn("loader.setSource", content)

    def test_widgets_have_safe_default_contexts(self) -> None:
        widgets = sorted((ROOT / "modules/shell/widgets").glob("*/Widget.qml"))
        self.assertTrue(widgets)
        for path in widgets:
            content = path.read_text(encoding="utf-8")
            self.assertNotIn("required property var context", content, str(path))
            self.assertIn("property var context:", content, str(path))
            self.assertIn("allows: function() { return false }", content, str(path))

    def test_dock_model_defers_group_rebuild(self) -> None:
        dock_model = (
            ROOT / "modules/shell/surfaces/desktop/DockModel.qml"
        ).read_text(encoding="utf-8")
        self.assertIn("property var groups: []", dock_model)
        self.assertNotIn("readonly property var groups: buildGroups(", dock_model)
        self.assertIn("onSourceToplevelsChanged: rebuildTimer.restart()", dock_model)

    def test_theme_reload_helpers_are_bounded(self) -> None:
        legacy_engine = (
            ROOT / "modules/theme-engine/bin/theme"
        ).read_text(encoding="utf-8")
        self.assertRegex(
            legacy_engine,
            r"def run_quiet\(command: list\[str\], timeout: float = [\d.]+\)",
        )
        self.assertIn("subprocess.TimeoutExpired", legacy_engine)

        runtime = (
            ROOT / "modules/theme-engine/bin/theme_runtime.py"
        ).read_text(encoding="utf-8")
        self.assertRegex(
            runtime,
            r"def _run_legacy\(name: str\)[\s\S]*?timeout=\d+",
        )

    def test_surface_geometry_is_bounded(self) -> None:
        bar = (
            ROOT / "modules/shell/surfaces/bar/BarSurface.qml"
        ).read_text(encoding="utf-8")
        desktop = (
            ROOT / "modules/shell/surfaces/desktop/DesktopSurface.qml"
        ).read_text(encoding="utf-8")
        for cell in ("startCell", "centerCell", "endCell"):
            self.assertIn(f"id: {cell}", bar)
        self.assertGreaterEqual(bar.count("Layout.fillWidth: true"), 3)
        self.assertIn("anchors.fill: parent", desktop)
        self.assertIn("exclusionMode: ExclusionMode.Ignore", desktop)
        self.assertIn("anchors.margins: Core.Theme.barPadding", bar)
        self.assertIn("Core.Theme.barOuterMargin", bar)
        self.assertNotIn("anchors.margins: Core.Theme.gap", bar)

    def test_quickshell_autostart_prevents_duplicate_instances(self) -> None:
        autostart = (
            ROOT / "modules/hyprland/config/conf/autostart.lua"
        ).read_text(encoding="utf-8")
        version = (
            ROOT / "modules/hyprland/config/.arch-wm-version"
        ).read_text(encoding="utf-8").strip()
        self.assertIn("qs --no-duplicate --config arch-wm", autostart)
        self.assertNotIn("qs -c arch-wm", autostart)
        self.assertIn("theme-sync.py", autostart)
        self.assertEqual(version, "2026.08.07.5")

    def test_universal_theme_contract_drives_shell_and_hyprland(self) -> None:
        schema = json.loads(
            (ROOT / "modules/theme-engine/schema/theme.schema.json").read_text()
        )
        style = schema["properties"]["style"]["properties"]
        for token in (
            "surface_opacity",
            "window_gap",
            "bar_padding",
            "animation_profile",
            "workspace_animation",
            "motion_scale",
        ):
            self.assertIn(token, style)

        shell_theme = (
            ROOT / "modules/shell/core/Theme.qml"
        ).read_text(encoding="utf-8")
        for token in (
            "surfaceBase",
            "surfaceRaised",
            "surfaceElevated",
            "surfaceOverlay",
            "surfaceHover",
            "windowGap",
            "barPadding",
            "surfaceOpacity",
            "animationProfile",
            "motionScale",
        ):
            self.assertIn(token, shell_theme)
        self.assertIn("barHeight - 16", shell_theme)

        hypr_sync = (
            ROOT / "modules/hyprland/config/scripts/theme-sync.py"
        ).read_text(encoding="utf-8")
        self.assertIn("theme-engine/generated/theme.json", hypr_sync)
        self.assertIn("window_gap", hypr_sync)
        self.assertIn("animation_profile", hypr_sync)
        self.assertIn("workspace_animation", hypr_sync)
        self.assertIn("motion_scale", hypr_sync)

    def test_shell_interactive_chrome_uses_theme_roles(self) -> None:
        pill = (ROOT / "modules/shell/components/PillBox.qml").read_text(encoding="utf-8")
        card = (ROOT / "modules/shell/surfaces/homepage/GlassCard.qml").read_text(encoding="utf-8")
        self.assertIn("Core.Theme.surfaceRaised", pill)
        self.assertIn("Core.Theme.surfaceHover", pill)
        self.assertIn("Core.Theme.barOutlineColor", pill)
        self.assertNotIn("Qt.rgba(1, 1, 1", pill)
        self.assertIn("Core.Theme.roles.border_subtle", card)
        self.assertNotIn("Qt.rgba(1, 1, 1", card)

    def test_modern_reference_themes_exist(self) -> None:
        for name, dark in (
            ("obsidian", True),
            ("porcelain", False),
            ("ultraviolet", True),
            ("sorbet", False),
        ):
            path = ROOT / "modules/theme-engine/themes" / f"{name}.json"
            self.assertTrue(path.is_file(), name)
            payload = json.loads(path.read_text(encoding="utf-8"))
            self.assertEqual(payload["name"], name)
            self.assertEqual(payload["dark"], dark)
            for role in (
                "surface_0",
                "surface_1",
                "surface_2",
                "overlay",
                "hover",
                "accent",
                "accent2",
            ):
                self.assertIn(role, payload["roles"])
            self.assertIn("window_gap", payload["style"])
            self.assertIn("bar_padding", payload["style"])
            self.assertGreaterEqual(payload["style"]["surface_opacity"], 0.9)

    def test_theme_validation_warns_about_flat_palettes(self) -> None:
        studio = (
            ROOT / "modules/theme-engine/bin/theme-studio"
        ).read_text(encoding="utf-8")
        self.assertIn("palette_quality_issues", studio)
        self.assertIn("low-saturation", studio)
        self.assertIn("look washed out", studio)
        self.assertIn("Bar padding leaves less than 16px", studio)

    def test_special_workspaces_and_smart_rules_exist(self) -> None:
        keybinds = (
            ROOT / "modules/hyprland/config/conf/keybinds.lua"
        ).read_text(encoding="utf-8")
        for workspace in ("scratch", "music", "comms"):
            self.assertIn(f'"{workspace}"', keybinds)
        self.assertIn("toggle_special", keybinds)

        rules = (
            ROOT / "modules/hyprland/config/conf/windowrules.lua"
        ).read_text(encoding="utf-8")
        for rule_name in (
            "arch-wm-settings-float",
            "arch-wm-file-picker-float",
            "arch-wm-auth-dialog-float",
            "arch-wm-picture-in-picture-float",
        ):
            self.assertIn(rule_name, rules)

    def test_menu_popup_dismisses_from_backdrop_and_escape(self) -> None:
        popup = (
            ROOT / "modules/shell/components/MenuPopup.qml"
        ).read_text(encoding="utf-8")
        version = (
            ROOT / "modules/shell/.arch-wm-version"
        ).read_text(encoding="utf-8").strip()
        self.assertIn("function close()", popup)
        self.assertRegex(popup, r"if \(menuOpen\)\s*(?:\{\s*)?close\(\)")
        self.assertIn("bottom: true", popup)
        self.assertIn("left: true", popup)
        self.assertRegex(popup, r"MouseArea\s*\{\s*anchors\.fill: parent;?\s*onClicked: popup\.close\(\)")
        self.assertRegex(popup, r"MouseArea\s*\{\s*anchors\.fill: parent;?\s*onClicked: \{\}\s*\}")
        self.assertIn("focus: popup.menuOpen", popup)
        self.assertIn("Keys.onEscapePressed: popup.close()", popup)
        self.assertIn("width: 340", popup)
        self.assertEqual(version, "2026.08.07.22")


if __name__ == "__main__":
    unittest.main()
