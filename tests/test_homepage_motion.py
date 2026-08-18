from __future__ import annotations

import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
GLASS_CARD = ROOT / "modules/shell/surfaces/homepage/GlassCard.qml"
ROADMAP = ROOT / "docs/SHELL-MOTION-ROADMAP.md"


class HomepageMotionTests(unittest.TestCase):
    def test_motion_roadmap_has_exactly_twenty_features(self) -> None:
        content = ROADMAP.read_text(encoding="utf-8")
        headings = re.findall(r"^## (\d+)\. ", content, flags=re.MULTILINE)
        self.assertEqual(headings, [str(index) for index in range(1, 21)])
        self.assertIn("## 1. Homepage assembly choreography", content)
        self.assertIn("## 20. Motion inspector and performance guardrails", content)

    def test_homepage_cards_use_layout_safe_fall_transform(self) -> None:
        content = GLASS_CARD.read_text(encoding="utf-8")
        self.assertIn("transform: Translate", content)
        self.assertIn("y: root.revealOffset", content)
        self.assertNotIn('property: "y"', content)
        self.assertNotIn("Behavior on y", content)
        self.assertIn("revealProgress", content)
        self.assertIn("revealScale", content)

    def test_homepage_motion_is_staggered_by_column(self) -> None:
        content = GLASS_CARD.read_text(encoding="utf-8")
        self.assertIn("function automaticAssemblyOrder()", content)
        self.assertIn("effectiveAssemblyOrder * 105", content)
        self.assertRegex(content, r"if \(ratio < 0\.28\)[\s\S]*?return 0")
        self.assertRegex(content, r"if \(ratio < 0\.78\)[\s\S]*?return 1")
        self.assertRegex(content, r"return 2")

    def test_homepage_motion_replays_on_window_visibility(self) -> None:
        content = GLASS_CARD.read_text(encoding="utf-8")
        self.assertIn("Window.visibility !== Window.Hidden", content)
        self.assertIn("onHostVisibleChanged", content)
        self.assertIn("Qt.callLater(root.startAssembly)", content)
        self.assertIn("revealDelay.restart()", content)
        self.assertIn("revealAnimation.restart()", content)

    def test_homepage_motion_has_bounce_and_reduced_motion_path(self) -> None:
        content = GLASS_CARD.read_text(encoding="utf-8")
        self.assertIn("Easing.OutBack", content)
        self.assertIn("easing.overshoot: 1.45", content)
        self.assertIn("Core.Theme.motionScale <= 0.05", content)
        self.assertIn("assemblyEnabled", content)
        self.assertIn("Core.Theme.homepageTransitionMs", content)


if __name__ == "__main__":
    unittest.main()
