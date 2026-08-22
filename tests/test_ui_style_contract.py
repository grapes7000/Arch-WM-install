from __future__ import annotations

import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
CORE = ROOT / "modules/shell/core"
COMPONENTS = ROOT / "modules/shell/components"
BAR = ROOT / "modules/shell/surfaces/bar"
HOMEPAGE = ROOT / "modules/shell/surfaces/homepage"
PROFILES = ROOT / "modules/theme-engine/ui-styles"


class UiStyleContractTests(unittest.TestCase):
    def test_ui_style_singleton_reads_generated_contract(self) -> None:
        content = (CORE / "UiStyle.qml").read_text(encoding="utf-8")
        qmldir = (CORE / "qmldir").read_text(encoding="utf-8")
        self.assertIn("singleton UiStyle 1.0 UiStyle.qml", qmldir)
        self.assertIn('theme-engine/generated/ui-style.json', content)
        self.assertIn('watchChanges: true', content)
        self.assertIn('schema_version !== 1', content)
        self.assertIn('keeping last known-good style', content)

    def test_geometry_is_owned_by_ui_style_not_palette(self) -> None:
        theme = (CORE / "Theme.qml").read_text(encoding="utf-8")
        for token in (
            "UiStyle.radiusSurface",
            "UiStyle.radiusControl",
            "UiStyle.radiusOverlay",
            "UiStyle.borderWidth",
            "UiStyle.controlHeightLarge",
            "UiStyle.spacingXs",
            "UiStyle.iconSize",
            "UiStyle.fontCaption",
        ):
            self.assertIn(token, theme)
        self.assertIn("barHeight - 16", theme)

    def test_bar_controls_use_semantic_geometry_and_motion(self) -> None:
        pill = (COMPONENTS / "PillBox.qml").read_text(encoding="utf-8")
        self.assertIn("radius: Core.UiStyle.radiusControl", pill)
        self.assertIn("border.width: Core.UiStyle.borderWidth", pill)
        self.assertIn("readonly property bool quiet: Core.UiStyle.quietButtons", pill)
        self.assertIn("Core.UiStyle.motionNone", pill)
        self.assertIn("Core.UiStyle.motionRestrained", pill)
        self.assertIn("Core.UiStyle.motionPlayful", pill)
        self.assertIn("Core.Theme.surfaceRaised", pill)
        self.assertIn("Core.Theme.surfaceHover", pill)
        self.assertNotIn("radius: Math.max(6", pill)

    def test_profiles_define_distinct_motion_personalities(self) -> None:
        precision = json.loads((PROFILES / "precision.json").read_text(encoding="utf-8"))
        legacy = json.loads((PROFILES / "legacy.json").read_text(encoding="utf-8"))
        win95 = json.loads((PROFILES / "win95.json").read_text(encoding="utf-8"))
        self.assertEqual(precision["patterns"]["motion"], "restrained")
        self.assertEqual(legacy["patterns"]["motion"], "playful")
        self.assertEqual(win95["patterns"]["motion"], "none")

    def test_launcher_exposes_precision_and_legacy_paths(self) -> None:
        launcher = (BAR / "LauncherOverlay.qml").read_text(encoding="utf-8")
        self.assertIn("Core.UiStyle.radiusOverlay", launcher)
        self.assertIn("Core.UiStyle.controlHeight", launcher)
        self.assertIn("Core.UiStyle.fontBody", launcher)
        self.assertIn("Core.UiStyle.quietButtons ? 1.0", launcher)
        self.assertIn("0.91 + launcherWindow.revealProgress * 0.09", launcher)

    def test_homepage_cards_are_profile_aware(self) -> None:
        glass = (HOMEPAGE / "GlassCard.qml").read_text(encoding="utf-8")
        pro = (HOMEPAGE / "ProCard.qml").read_text(encoding="utf-8")
        self.assertIn("readonly property bool precision: Core.UiStyle.flatSurfaces", glass)
        self.assertIn("visible: root.angledShadow && Core.Theme.shadowEnabled && !root.precision", glass)
        self.assertIn("border.width: Core.UiStyle.borderWidth", glass)
        self.assertIn("property int contentPadding: Core.UiStyle.spacingMd", pro)
        self.assertIn("bounce: Core.UiStyle.quietButtons", pro)


if __name__ == "__main__":
    unittest.main()
