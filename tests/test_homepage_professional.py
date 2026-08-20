from __future__ import annotations

import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
HOMEPAGE = ROOT / "modules/shell/surfaces/homepage"
BAR = ROOT / "modules/shell/surfaces/bar"
HYPRLAND_BINDS = ROOT / "modules/hyprland/config/conf/keybinds.lua"


class ProfessionalHomepageTests(unittest.TestCase):
    def test_reusable_professional_components_are_registered(self) -> None:
        qmldir = (HOMEPAGE / "qmldir").read_text(encoding="utf-8")
        for name in ("ProCard", "StatusChip", "MetricTile", "Sparkline", "QuickAccessPanel"):
            path = HOMEPAGE / f"{name}.qml"
            self.assertTrue(path.is_file(), name)
            self.assertIn(f"{name} 1.0 {name}.qml", qmldir)

    def test_bar_runtime_uses_known_good_direct_widget_hosts(self) -> None:
        surface = (BAR / "BarSurface.qml").read_text(encoding="utf-8")
        self.assertEqual(surface.count("WidgetHost {"), 4)
        self.assertNotIn("BarMotionHost {", surface)
        self.assertGreaterEqual(surface.count("required property var modelData"), 5)
        self.assertGreaterEqual(surface.count("widgetId: modelData.widget"), 4)
        self.assertGreaterEqual(surface.count("instanceId: modelData.instance"), 4)
        for token in (
            "Services.LayoutService.bar.regions.start || []",
            "Services.LayoutService.bar.regions.center || []",
            "Services.LayoutService.bar.regions.end || []",
        ):
            self.assertIn(token, surface)

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
        self.assertIn("Layout.minimumHeight: implicitHeight", content)

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

    def test_homepage_uses_centered_orbit_and_live_history(self) -> None:
        content = (HOMEPAGE / "HomepageSurface.qml").read_text(encoding="utf-8")
        glass = (HOMEPAGE / "GlassCard.qml").read_text(encoding="utf-8")
        self.assertEqual(content.count("GlassCard {"), 2)
        self.assertIn("NowPlayingCard {", content)
        self.assertIn("LiveActivityCard {", content)
        self.assertIn("FloatingAppCluster {", content)
        self.assertNotIn("ProCard {", content)
        self.assertIn("property var cpuHistory", content)
        self.assertIn("property var memoryHistory", content)
        self.assertIn("property var diskHistory", content)
        self.assertIn("function appendHistory", content)
        self.assertIn("interval: 2000", content)
        self.assertNotIn("component StatBar", content)
        self.assertIn("x: Math.min(homeSurface.width + root.sideGap,", content)
        self.assertIn("y: root.appClusterTop", content)
        self.assertIn("width: root.compact ? 400 : 440", content)
        self.assertGreaterEqual(content.count("superDraggable: true"), 4)
        self.assertIn("property bool angledShadow", glass)
        self.assertIn("Core.Theme.shadowEnabled", glass)
        self.assertIn("Core.Theme.shadowColor", glass)
        self.assertIn("Core.Theme.shadowOpacity", glass)
        self.assertIn("DragHandler {", glass)
        self.assertIn("acceptedModifiers: Qt.MetaModifier", glass)

        keybinds = HYPRLAND_BINDS.read_text(encoding="utf-8")
        self.assertIn(
            'hl.bind(main .. " + mouse:272", hl.dsp.window.drag(), '
            "{ drag = true, non_consuming = true })",
            keybinds,
        )

    def test_managed_shell_version_is_bumped(self) -> None:
        version = (ROOT / "modules/shell/.arch-wm-version").read_text(encoding="utf-8").strip()
        self.assertEqual(version, "2026.08.07.22")


if __name__ == "__main__":
    unittest.main()
