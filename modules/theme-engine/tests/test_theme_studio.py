"""Regression tests for Theme Studio's live preview, Lua renderer, and schema.

Run with:  PYTHONPATH=bin python -m unittest discover -s tests -p 'test_theme_studio.py' -v

The suite is hermetic: it redirects HOME/XDG_CONFIG_HOME to a temporary
directory before importing the theme modules, and disables Hyprland reloads.
"""
from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

_ROOT = tempfile.mkdtemp(prefix="theme-studio-test-")
os.environ["HOME"] = str(Path(_ROOT) / "home")
os.environ["XDG_CONFIG_HOME"] = str(Path(_ROOT) / "config")
os.environ.pop("HYPRLAND_INSTANCE_SIGNATURE", None)

_BIN = Path(__file__).resolve().parents[1] / "bin"
sys.path.insert(0, str(_BIN))

import theme_components  # noqa: E402
from theme_components import render_hypr_lua  # noqa: E402
import theme_editor  # noqa: E402
import theme_runtime  # noqa: E402
from theme_schema import ensure_theme_schema  # noqa: E402

ROLES = {
    "bg": "#111111", "bg_alt": "#1b1b1b", "text": "#e8e8ec",
    "text_dim": "#8a8a93", "accent": "#ff3cac", "accent2": "#ff1493",
    "urgent": "#ff5f78", "focus": "#ff3cac", "border_normal": "#3a3a44",
}


class ThemeStudioSchemaTest(unittest.TestCase):
    def test_schema_has_no_waybar_or_launcher(self) -> None:
        theme = ensure_theme_schema({"name": "x", "roles": ROLES, "style": {}, "components": {}})
        self.assertNotIn("waybar", theme["components"])
        self.assertNotIn("launcher", theme["components"])
        self.assertNotIn("waybar_preset", theme["style"])
        self.assertNotIn("bar_blur", theme["style"])

    def test_legacy_themes_with_waybar_data_still_load(self) -> None:
        # Old JSON files keep stale waybar/launcher data; they must be tolerated.
        theme = ensure_theme_schema({
            "name": "old", "roles": ROLES, "style": {},
            "components": {"waybar": {"layout": "islands"}, "launcher": {"width": 640}},
        })
        self.assertEqual(theme["components"]["waybar"]["layout"], "islands")


class HyprLuaRendererTest(unittest.TestCase):
    def test_lua_module_shape(self) -> None:
        theme = ensure_theme_schema({"name": "y", "roles": ROLES, "style": {}, "components": {}})
        lua = render_hypr_lua(theme)
        self.assertIn("hl.config({", lua)
        self.assertIn("gaps_out = 10", lua)
        # every rgba(...) must be closed so Hyprland can parse the color
        self.assertNotIn("rgba(", lua.replace("rgba(", "x(").replace("rgba", "c"))
        for line in lua.splitlines():
            if "inactive_border" in line:
                self.assertTrue(line.rstrip().endswith("\","), line)

    def test_lua_gradient_border(self) -> None:
        theme = ensure_theme_schema({"name": "y", "roles": ROLES, "style": {}, "components": {}})
        theme["components"]["windows"]["active_border"].update({"style": "gradient", "angle": 90})
        lua = render_hypr_lua(theme)
        self.assertIn('colors = { "rgba(', lua)
        self.assertIn("angle = 90", lua)

    def test_lua_includes_animation_preset(self) -> None:
        theme = ensure_theme_schema({"name": "y", "roles": ROLES, "style": {}, "components": {}})
        theme["style"]["animation_preset"] = "bouncy"
        lua = render_hypr_lua(theme)
        # The Lua module must carry hl.curve/hl.animation calls so the live
        # preview and generated/theme.lua animate exactly like the conf file.
        self.assertIn('hl.config({ animations = { enabled = true } })', lua)
        self.assertIn('hl.curve("spring",', lua)
        self.assertIn('hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "spring"', lua)
        self.assertIn('style = "popin 60%"', lua)

    def test_lua_none_preset_disables_animations(self) -> None:
        theme = ensure_theme_schema({"name": "y", "roles": ROLES, "style": {}, "components": {}})
        theme["style"]["animation_preset"] = "none"
        lua = render_hypr_lua(theme)
        self.assertIn("animations = { enabled = false }", lua)
        self.assertNotIn("hl.animation(", lua)

    def test_conf_renderer_disables_animations_for_none(self) -> None:
        theme = ensure_theme_schema({"name": "y", "roles": ROLES, "style": {}, "components": {}})
        theme["style"]["animation_preset"] = "none"
        conf = theme_components.render_hypr(theme)
        self.assertIn("enabled = false", conf)
        self.assertIn("animations {", conf)


class SaveFlowTest(unittest.TestCase):
    def setUp(self) -> None:
        self.theme_dir = Path(os.environ["XDG_CONFIG_HOME"]) / "theme-engine/themes"
        self.theme_dir.mkdir(parents=True, exist_ok=True)
        payload = {"name": "y2k", "roles": ROLES, "style": {}, "components": {}}
        (self.theme_dir / "y2k.json").write_text(json.dumps(payload), encoding="utf-8")

    def test_save_as_syncs_inner_name(self) -> None:
        # The legacy generator rejects files whose inner name differs from the
        # filename; save-as must rewrite the name or applies silently stall.
        editor = theme_editor.ThemeEditor("y2k", self.theme_dir)
        editor.save("y2k_custom", replace=False, apply=False)
        saved = json.loads((self.theme_dir / "y2k_custom.json").read_text(encoding="utf-8"))
        self.assertEqual(saved["name"], "y2k_custom")
        self.assertEqual(editor.theme_name, "y2k_custom")

    def test_duplicate_and_rename_sync_names(self) -> None:
        theme_editor.duplicate_theme("y2k", "y2k_dup", self.theme_dir)
        dup = json.loads((self.theme_dir / "y2k_dup.json").read_text(encoding="utf-8"))
        self.assertEqual(dup["name"], "y2k_dup")
        theme_editor.rename_theme("y2k_dup", "y2k_renamed", self.theme_dir)
        renamed = json.loads((self.theme_dir / "y2k_renamed.json").read_text(encoding="utf-8"))
        self.assertEqual(renamed["name"], "y2k_renamed")
        self.assertFalse((self.theme_dir / "y2k_dup.json").exists())

    def test_list_themes_filters_preview_artifacts(self) -> None:
        ghost = self.theme_dir / "_theme_studio_preview.json"
        ghost.write_text("{}", encoding="utf-8")
        names = theme_editor.list_themes(self.theme_dir)
        self.assertNotIn("_theme_studio_preview", names)
        self.assertIn("y2k", names)
        ghost.unlink()  # do not leak the artifact into sibling tests

    def test_preview_draft_stays_outside_themes_dir(self) -> None:
        theme = theme_runtime.load_theme("y2k")
        theme_runtime.write_preview(theme)
        generated = Path(os.environ["XDG_CONFIG_HOME"]) / "theme-engine/generated"
        self.assertTrue((generated / "_theme_studio_preview.json").is_file())
        self.assertFalse((self.theme_dir / "_theme_studio_preview.json").exists())
        self.assertNotIn("_theme_studio_preview", theme_editor.list_themes(self.theme_dir))


class PromptStarshipTest(unittest.TestCase):
    def setUp(self) -> None:
        theme_dir = Path(os.environ["XDG_CONFIG_HOME"]) / "theme-engine/themes"
        theme_dir.mkdir(parents=True, exist_ok=True)
        payload = {"name": "y2k", "roles": ROLES, "style": {}, "components": {}}
        (theme_dir / "y2k.json").write_text(json.dumps(payload), encoding="utf-8")
        self.theme = theme_runtime.load_theme("y2k")

    def test_apply_prompt_renders_real_starship_toml(self) -> None:
        self.theme["components"]["prompt"]["show_battery"] = True
        self.theme["components"]["prompt"]["directory_role"] = "accent2"
        theme_components.apply_prompt(self.theme)
        path = Path(os.environ["XDG_CONFIG_HOME"]) / "theme-engine/generated/starship.toml"
        self.assertTrue(path.is_file())
        text = path.read_text(encoding="utf-8")
        # directory_role is honored: the directory style uses the accent2 hex.
        self.assertIn("bg:#ff1493", text)
        # show_battery=True must flip the battery module on (scoped to its block).
        battery = text.split("[battery]", 1)[1]
        self.assertIn("disabled = false", battery.split("[[battery.display]]")[0])
        # no dead starship-studio.json is written anymore
        self.assertFalse((Path(os.environ["XDG_CONFIG_HOME"]) / "theme-engine/starship-studio.json").exists())

    def test_render_hypr_has_no_waybar_layerrule(self) -> None:
        hypr = theme_components.render_hypr(self.theme)
        self.assertNotIn("waybar", hypr.lower())
        self.assertNotIn("layerrule", hypr.lower())

    def test_schema_field_help_is_populated(self) -> None:
        # The TUI explains every setting; key fields must carry plain help.
        from theme_schema import COMPONENT_FIELDS
        self.assertTrue(COMPONENT_FIELDS["windows"][0].help)
        self.assertIn("pixels", COMPONENT_FIELDS["windows"][0].help)
        self.assertTrue(COMPONENT_FIELDS["prompt"][0].help)

    def test_legacy_generator_has_no_waybar_renderers(self) -> None:
        src = Path(_BIN / "theme").read_text(encoding="utf-8")
        for function in ("render_waybar", "render_wofi", "render_rofi"):
            self.assertNotIn(function, src)

    def test_legacy_starship_delegates_to_fancy_generator(self) -> None:
        # The legacy generator must produce the same two-line, palette-driven
        # prompt as Theme Studio, not the old minimal one-liner.
        import types
        src = Path(_BIN / "theme").read_text(encoding="utf-8")
        module = types.ModuleType("legacy_theme")
        module.__file__ = str(_BIN / "theme")
        exec(compile(src, "theme", "exec"), module.__dict__)
        roles = dict(ROLES)
        roles.update({"on_accent": "#111111", "on_urgent": "#ffffff", "selected": "#ff3cac"})
        theme = module.normalize({"name": "y2k", "roles": roles, "style": {}})
        out = module.render_starship(theme)
        self.assertIn('palette = "theme"', out)
        self.assertIn("right_format", out)
        self.assertIn("[directory]", out)
        self.assertNotIn('format = "$directory$git_branch$git_status$character"', out)


class LivePreviewTest(unittest.TestCase):
    def setUp(self) -> None:
        os.environ.pop("THEME_LEGACY_COMMAND", None)
        (Path(_ROOT) / "legacy.log").unlink(missing_ok=True)
        theme_dir = Path(os.environ["XDG_CONFIG_HOME"]) / "theme-engine/themes"
        theme_dir.mkdir(parents=True, exist_ok=True)
        payload = {"name": "y2k", "roles": ROLES, "style": {}, "components": {}}
        (theme_dir / "y2k.json").write_text(json.dumps(payload), encoding="utf-8")
        self.theme = theme_runtime.load_theme("y2k")
        self.generated = Path(os.environ["XDG_CONFIG_HOME"]) / "hypr/generated"

    def _fake_legacy(self) -> Path:
        log = Path(_ROOT) / "legacy.log"
        script = Path(_ROOT) / "fake-legacy"
        script.write_text(f"#!/bin/sh\necho \"$@\" >> {log}\nexit 0\n", encoding="utf-8")
        script.chmod(0o755)
        os.environ["THEME_LEGACY_COMMAND"] = str(script)
        return log

    def test_preview_writes_live_files_without_legacy(self) -> None:
        log = self._fake_legacy()
        self.theme["roles"]["accent"] = "#ff5aa5"
        self.theme["components"]["windows"]["gaps_out"] = 24
        result = theme_runtime.preview_theme(self.theme, reason="test")
        self.assertTrue(result["live"])
        conf = self.generated / "theme.conf"
        lua = self.generated / "theme.lua"
        self.assertTrue(conf.is_file())
        self.assertTrue(lua.is_file())
        self.assertIn("gaps_out = 24", conf.read_text(encoding="utf-8"))
        self.assertIn("gaps_out = 24", lua.read_text(encoding="utf-8"))
        self.assertIn("ff5aa5", conf.read_text(encoding="utf-8").lower())
        # the preview must never round-trip through the legacy generator
        self.assertFalse(log.exists(), "preview invoked the legacy generator")

    def test_full_apply_still_invokes_legacy(self) -> None:
        log = self._fake_legacy()
        theme_runtime.apply_theme("y2k")
        self.assertTrue(log.exists())
        self.assertIn("y2k", log.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
