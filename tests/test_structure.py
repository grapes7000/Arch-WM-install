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
            "component.createObject(root, { context: widgetContext })",
            content,
        )
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
        self.assertEqual(version, "2026.08.04.3")

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
        self.assertEqual(version, "2026.08.06.5")


if __name__ == "__main__":
    unittest.main()
