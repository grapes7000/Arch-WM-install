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

    def test_homepage_cards_use_layout_safe_directional_transform(self) -> None:
        content = GLASS_CARD.read_text(encoding="utf-8")
        self.assertIn("transform: Translate", content)
        self.assertIn("x: root.revealOffsetX", content)
        self.assertIn("y: root.revealOffsetY", content)
        self.assertNotIn('property: "x"', content)
        self.assertNotIn('property: "y"', content)
        self.assertNotIn("Behavior on x", content)
        self.assertNotIn("Behavior on y", content)
        self.assertIn("revealProgress", content)
        self.assertIn("revealScale", content)
        self.assertIn("revealDistance", content)

    def test_homepage_motion_is_clockwise_and_card_by_card(self) -> None:
        content = GLASS_CARD.read_text(encoding="utf-8")
        self.assertIn("function layoutMetrics()", content)
        self.assertIn("function automaticAssemblyOrder()", content)
        self.assertIn("function automaticAssemblyDirection()", content)
        self.assertIn("effectiveAssemblyOrder * 145", content)
        self.assertIn("return 0.9 + metrics.vertical * 3.3", content)
        self.assertIn("return 5.1 + (1.0 - metrics.vertical) * 3.4", content)
        self.assertIn('return "left"', content)
        self.assertIn('return "right"', content)
        self.assertIn('return metrics.topmost ? "top" : "bottom"', content)
        self.assertRegex(
            content,
            r"if \(metrics\.topmost\)\s+return 0",
        )

    def test_homepage_motion_is_deliberately_slower(self) -> None:
        content = GLASS_CARD.read_text(encoding="utf-8")
        self.assertIn("effectiveAssemblyOrder * 145", content)
        self.assertIn("Math.max(420, Core.Theme.homepageTransitionMs)", content)

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
