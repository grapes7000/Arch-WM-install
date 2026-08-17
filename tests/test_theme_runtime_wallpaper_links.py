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
# provide tiny import stubs so theme_runtime can be imported without pulling
# in the real, heavier theme_components/theme_schema modules.
#
# These MUST be restored immediately after importing theme_runtime, not
# deferred to tearDownModule(): pytest imports every test module during its
# collection phase, before any test runs, so a stub left in sys.modules here
# is already visible to every other test file by the time any teardown could
# run. Plain `sys.modules.setdefault(...)` alone leaked these stubs for the
# rest of the process; a test module collected afterwards (e.g.
# test_theme_studio.py) doing a plain `import theme_components` picked up
# this stub instead of the real module and failed on `render_hypr_lua` and
# other real attributes it lacks. We only install a stub when the real
# module isn't already imported, and remove exactly what we installed right
# after theme_runtime is done importing it.
_STUBBED_MODULES: dict[str, object] = {}


def _install_stub(name: str, module: types.ModuleType) -> None:
    if name in sys.modules:
        return
    sys.modules[name] = module
    _STUBBED_MODULES[name] = module


components = types.ModuleType("theme_components")
components.apply_all = lambda *_args, **_kwargs: {}
_install_stub("theme_components", components)

schema = types.ModuleType("theme_schema")
schema.dump_json = lambda _data: "{}"
schema.ensure_theme_schema = lambda data: data
schema.safe_theme_name = lambda name: name
_install_stub("theme_schema", schema)

import theme_runtime

for _name, _module in _STUBBED_MODULES.items():
    if sys.modules.get(_name) is _module:
        del sys.modules[_name]


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
