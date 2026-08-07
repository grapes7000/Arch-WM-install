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
        # Widget content is created inside the animated pill container on the
        # bar so hover/press state bubbles up; the context is still passed at
        # construction time either way.
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
        self.assertEqual(version, "2026.08.07.2")

    def test_universal_theme_contract_drives_shell_and_hyprland(self) -> None:
        schema = json.loads(
            (ROOT / "modules/theme-engine/schema/theme.schema.json").read_text()
        )
        style = schema["properties"]["style"]["properties"]
        for token in (
            "surface_opacity",
            "animation_profile",
            "workspace_animation",
            "motion_scale",
        ):
            self.assertIn(token, style)

        shell_theme = (
            ROOT / "modules/shell/core/Theme.qml"
        ).read_text(encoding="utf-8")
        self.assertIn("surfaceOpacity", shell_theme)
        self.assertIn("animationProfile", shell_theme)
        self.assertIn("motionScale", shell_theme)

        hypr_sync = (
            ROOT / "modules/hyprland/config/scripts/theme-sync.py"
        ).read_text(encoding="utf-8")
        self.assertIn("theme-engine/generated/theme.json", hypr_sync)
        self.assertIn("animation_profile", hypr_sync)
        self.assertIn("workspace_animation", hypr_sync)
        self.assertIn("motion_scale", hypr_sync)

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
        self.assertRegex(popup, r"if \(menuOpen\) \{\s+close\(\)")
        self.assertIn("bottom: true", popup)
        self.assertIn("left: true", popup)
        self.assertRegex(
            popup,
            r"id: backdrop\s+anchors\.fill: parent\s+onClicked: popup\.close\(\)",
        )
        self.assertRegex(
            popup,
            r"id: cardClickShield\s+anchors\.fill: parent\s+onClicked: \{\}",
        )
        self.assertIn("focus: popup.menuOpen", popup)
        self.assertIn("Keys.onEscapePressed: popup.close()", popup)
        self.assertIn("width: 340", popup)
        self.assertEqual(version, "2026.08.07.14")


if __name__ == "__main__":
    unittest.main()
