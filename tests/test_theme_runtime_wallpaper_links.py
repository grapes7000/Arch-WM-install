"""Semantic wallpaper renders must publish stable, retargeting symlinks."""
from __future__ import annotations

import sys
import tempfile
import types
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "modules/theme-engine/bin"))

# theme_runtime's component modules are optional in this focused unit test;
# provide tiny import stubs so the symlink helpers can be tested in isolation.
components = types.ModuleType("theme_components")
components.apply_all = lambda *_args, **_kwargs: {}
sys.modules.setdefault("theme_components", components)

schema = types.ModuleType("theme_schema")
schema.dump_json = lambda _data: "{}"
schema.ensure_theme_schema = lambda data: data
schema.safe_theme_name = lambda name: name
sys.modules.setdefault("theme_schema", schema)

import theme_runtime


class PublishCurrentWallpaperTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        tmp_path = Path(self._tmp.name)
        self.cfg = tmp_path / "config"
        self.cache = tmp_path / "cache"
        self._original_cfg = theme_runtime.CFG
        self._original_cache = theme_runtime.CACHE
        self._original_render_root = theme_runtime.RENDER_ROOT
        theme_runtime.CFG = self.cfg
        theme_runtime.CACHE = self.cache
        theme_runtime.RENDER_ROOT = self.cache / "theme-engine" / "wallpapers"
        self.addCleanup(self._restore)

    def _restore(self) -> None:
        theme_runtime.CFG = self._original_cfg
        theme_runtime.CACHE = self._original_cache
        theme_runtime.RENDER_ROOT = self._original_render_root

    def test_creates_stable_symlink_chain(self) -> None:
        rendered = self.cache / "theme-engine" / "wallpapers" / "arch-retro" / "nord.png"
        rendered.parent.mkdir(parents=True)
        rendered.write_bytes(b"nord")

        current, homepage = theme_runtime._publish_current_wallpaper(rendered)

        self.assertEqual(current, self.cache / "theme-engine" / "wallpapers" / "current.png")
        self.assertEqual(homepage, self.cfg / "quickshell" / "homepage-images" / "theme-wallpaper.png")
        self.assertTrue(current.is_symlink())
        self.assertTrue(homepage.is_symlink())
        self.assertEqual(current.resolve(), rendered.resolve())
        self.assertEqual(homepage.resolve(), rendered.resolve())

    def test_retargets_links_on_theme_change(self) -> None:
        nord = self.cache / "theme-engine" / "wallpapers" / "arch-retro" / "nord.png"
        gruvbox = self.cache / "theme-engine" / "wallpapers" / "arch-retro" / "gruvbox.png"
        nord.parent.mkdir(parents=True)
        nord.write_bytes(b"nord")
        gruvbox.write_bytes(b"gruvbox")

        current, homepage = theme_runtime._publish_current_wallpaper(nord)
        self.assertEqual(homepage.resolve(), nord.resolve())

        theme_runtime._publish_current_wallpaper(gruvbox)
        self.assertEqual(current.resolve(), gruvbox.resolve())
        self.assertEqual(homepage.resolve(), gruvbox.resolve())


if __name__ == "__main__":
    unittest.main()
