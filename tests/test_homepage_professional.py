from __future__ import annotations

import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
HOMEPAGE = ROOT / "modules/shell/surfaces/homepage"
BAR = ROOT / "modules/shell/surfaces/bar"


class ProfessionalHomepageTests(unittest.TestCase):
    def test_reusable_professional_components_are_registered(self) -> None:
        qmldir = (HOMEPAGE / "qmldir").read_text(encoding="utf-8")
        for name in ("ProCard", "StatusChip", "MetricTile", "Sparkline", "QuickAccessPanel"):
            path = HOMEPAGE / f"{name}.qml"
            self.assertTrue(path.is_file(), name)
            self.assertIn(f"{name} 1.0 {name}.qml", qmldir)

    def test_bar_motion_host_is_registered_for_runtime_loading(self) -> None:
        qmldir = (BAR / "qmldir").read_text(encoding="utf-8")
        self.assertTrue((BAR / "BarMotionHost.qml").is_file())
        self.assertIn("BarMotionHost 1.0 BarMotionHost.qml", qmldir)

    def test_bar_motion_repeater_entries_are_bound_explicitly(self) -> None:
        host = (BAR / "BarMotionHost.qml").read_text(encoding="utf-8")
        surface = (BAR / "BarSurface.qml").read_text(encoding="utf-8")
        self.assertIn("required property var entry", host)
        self.assertNotIn("required property var modelData", host)
        self.assertIn("root.entry.widget", host)
        self.assertEqual(surface.count("BarMotionHost {"), 4)
        self.assertEqual(surface.count("entry: modelData"), 4)
        self.assertNotIn("required property var modelData\n                                    required property int index", surface)

    def test_pro_card_has_visual_hierarchy_and_status_slot(self) -> None:
        content = (HOMEPAGE / "ProCard.qml").read_text(encoding="utf-8")
        self.assertIn("GlassCard {", content)
        self.assertIn("default property alias bodyData", content)
        self.assertIn("property string eyebrow", content)
        self.assertIn("property string title", content)
        self.assertIn("property string subtitle", content)
        self.assertIn("StatusChip {", content)
        self.assertIn("Core.Theme.alphaColor(Core.Theme.accent", content)
        self.assertIn("anchors.top: parent.top", content)

    def test_metric_and_sparkline_components_are_data_driven(self) -> None:
        metric = (HOMEPAGE / "MetricTile.qml").read_text(encoding="utf-8")
        sparkline = (HOMEPAGE / "Sparkline.qml").read_text(encoding="utf-8")
        self.assertIn("property real value", metric)
        self.assertIn("Behavior on width", metric)
        self.assertIn("property var samples", sparkline)
        self.assertIn('getContext("2d")', sparkline)
        self.assertIn("requestPaint()", sparkline)

    def test_quick_access_integrates_launcher_places_and_git_projects(self) -> None:
        content = (HOMEPAGE / "QuickAccessPanel.qml").read_text(encoding="utf-8")
        self.assertIn('Core.InteractiveShellController.launcher("open")', content)
        self.assertIn('key: "apps"', content)
        self.assertIn('key: "places"', content)
        self.assertIn('key: "projects"', content)
        self.assertIn("$HOME/Projects", content)
        self.assertIn("$HOME/Code", content)
        self.assertIn("$HOME/Developer", content)
        self.assertIn('["xdg-open", path]', content)
        self.assertIn('["kitty", "--directory", path]', content)
        self.assertNotIn("eval(", content)

    def test_homepage_uses_professional_cards_and_live_history(self) -> None:
        content = (HOMEPAGE / "HomepageSurface.qml").read_text(encoding="utf-8")
        self.assertGreaterEqual(content.count("ProCard {"), 6)
        self.assertIn("QuickAccessPanel {", content)
        self.assertGreaterEqual(content.count("MetricTile {"), 5)
        self.assertIn("Sparkline {", content)
        self.assertIn("property var cpuHistory", content)
        self.assertIn("function appendHistory", content)
        self.assertIn("interval: 2000", content)
        self.assertNotIn("component StatBar", content)

    def test_managed_shell_version_is_bumped(self) -> None:
        version = (ROOT / "modules/shell/.arch-wm-version").read_text(encoding="utf-8").strip()
        self.assertEqual(version, "2026.08.07.22")


if __name__ == "__main__":
    unittest.main()
