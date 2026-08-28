from __future__ import annotations

import inspect
import unittest

from installer import fixed_entry


class StandaloneThemeStageTests(unittest.TestCase):
    def test_theme_stage_uses_standalone_catalog_paths(self) -> None:
        source = inspect.getsource(fixed_entry)
        self.assertIn('ctx.config / "hypr/themes"', source)
        self.assertIn('ctx.config / "hypr/generated/.active"', source)
        self.assertNotIn('theme-engine/generated/theme.json', source)

    def test_arch_wm_can_fetch_themes_itself(self) -> None:
        source = inspect.getsource(fixed_entry.install_or_refresh_themes)
        self.assertIn("grapes7000/themes.git", source)
        self.assertIn('"--targets", "full"', source)

    def test_stage_40_is_replaced(self) -> None:
        source = inspect.getsource(fixed_entry.patch_theme_stage)
        self.assertIn('"40-theme-engine"', source)
        self.assertIn("theme_check", source)
        self.assertIn("theme_apply", source)
        self.assertIn("theme_verify", source)


if __name__ == "__main__":
    unittest.main()
