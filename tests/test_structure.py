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

    def test_widget_context_is_an_initial_loader_property(self) -> None:
        content = (
            ROOT / "modules/shell/components/WidgetHost.qml"
        ).read_text(encoding="utf-8")
        self.assertIn(
            "loader.setSource(url, { context: widgetContext })",
            content,
        )
        self.assertNotIn("item.context = widgetContext", content)

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


if __name__ == "__main__":
    unittest.main()
