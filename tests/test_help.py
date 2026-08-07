from __future__ import annotations

import contextlib
import io
import os
import pathlib
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

sys.path.insert(0, str(ROOT))

from installer.help import (
    HELP_LAUNCHER,
    parse_keybinds,
    render_reference,
)
from installer.runtime import Context, Options


def _isolated_environment() -> tuple[dict[str, str], dict[str, str]]:
    environment = {
        "HOME": str(pathlib.Path(tempfile.mkdtemp()) / "home"),
        "XDG_CONFIG_HOME": str(pathlib.Path(tempfile.mkdtemp()) / "config"),
        "XDG_DATA_HOME": str(pathlib.Path(tempfile.mkdtemp()) / "data"),
        "XDG_STATE_HOME": str(pathlib.Path(tempfile.mkdtemp()) / "state"),
    }
    previous = {key: os.environ.get(key) for key in environment}
    return environment, previous


class KeybindParseTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        source = ROOT / "modules/hyprland/config/conf/keybinds.lua"
        cls.binds = parse_keybinds(source.read_text(encoding="utf-8"))
        cls.by_key = dict(cls.binds)

    def test_direct_binds_carry_descriptions(self) -> None:
        self.assertEqual(self.by_key.get("SUPER + Enter"), "Open terminal")
        self.assertEqual(self.by_key.get("SUPER + Space"), "Open application launcher")
        self.assertEqual(self.by_key.get("SUPER + Q"), "Close active window")
        self.assertEqual(self.by_key.get("SUPER + L"), "Lock session")
        self.assertEqual(self.by_key.get("SUPER + T"), "Choose desktop theme")
        self.assertEqual(self.by_key.get("SUPER + S"), "Capture selected region")
        self.assertEqual(self.by_key.get("Print"), "Capture full screen")

    def test_direction_loop_expands(self) -> None:
        self.assertEqual(self.by_key.get("SUPER + H"), "Focus window left")
        self.assertEqual(self.by_key.get("SUPER + SHIFT + J"), "Move window down")
        self.assertEqual(self.by_key.get("SUPER + left"), "Focus window left")
        self.assertEqual(self.by_key.get("SUPER + right"), "Focus window right")

    def test_workspace_loop_expands(self) -> None:
        self.assertEqual(self.by_key.get("SUPER + 1"), "Go to workspace 1")
        self.assertEqual(self.by_key.get("SUPER + 0"), "Go to workspace 10")
        self.assertEqual(self.by_key.get("SUPER + SHIFT + 3"), "Move window to workspace 3")

    def test_special_workspaces_expand(self) -> None:
        self.assertEqual(
            self.by_key.get("SUPER + Z"), "Toggle scratch special workspace"
        )
        self.assertEqual(self.by_key.get("SUPER + N"), "Toggle music special workspace")
        self.assertEqual(
            self.by_key.get("SUPER + SHIFT + C"), "Move window to comms special workspace"
        )

    def test_mouse_and_media_binds(self) -> None:
        self.assertEqual(self.by_key.get("SUPER + Scroll Down"), "Next workspace")
        self.assertEqual(self.by_key.get("SUPER + Scroll Up"), "Previous workspace")
        self.assertEqual(self.by_key.get("SUPER + Left Mouse"), "Drag window")
        self.assertEqual(self.by_key.get("SUPER + Right Mouse"), "Resize window")
        self.assertIn("XF86AudioRaiseVolume", self.by_key)
        self.assertIn("XF86MonBrightnessUp", self.by_key)

    def test_no_duplicate_keys(self) -> None:
        keys = [key for key, _ in self.binds]
        self.assertEqual(len(keys), len(set(keys)), keys)


class HelpReferenceTests(unittest.TestCase):
    def test_render_reference_covers_sections_and_locations(self) -> None:
        environment, previous = _isolated_environment()
        os.environ.update(environment)
        try:
            context = Context(ROOT, Options(command="help"))
            text = render_reference(context)
        finally:
            for key, value in previous.items():
                if value is None:
                    os.environ.pop(key, None)
                else:
                    os.environ[key] = value

        self.assertIn("KEYBINDS", text)
        self.assertIn("SUPER + Enter", text)
        self.assertIn("IMPORTANT FILE LOCATIONS", text)
        self.assertIn("quickshell/homepage-images", text)
        self.assertIn("theme-engine/generated/theme.json", text)
        self.assertIn("Pictures/Screenshots", text)
        self.assertIn("QUICK COMMANDS", text)
        self.assertIn("arch-wm-help", text)

    def test_installer_help_subcommand_prints_reference(self) -> None:
        environment, previous = _isolated_environment()
        os.environ.update(environment)
        try:
            from installer import entry

            stream = io.StringIO()
            with contextlib.redirect_stdout(stream):
                status = entry.main(["help"])
            self.assertEqual(status, 0)
            output = stream.getvalue()
            self.assertIn("KEYBINDS", output)
            self.assertIn("SUPER + Enter", output)
            self.assertIn("arch-wm/help.txt", output)
        finally:
            for key, value in previous.items():
                if value is None:
                    os.environ.pop(key, None)
                else:
                    os.environ[key] = value

    def test_launcher_script_is_portable_sh(self) -> None:
        self.assertTrue(HELP_LAUNCHER.startswith("#!/usr/bin/env sh"))
        self.assertIn("arch-wm/help.txt", HELP_LAUNCHER)
        self.assertIn("cat \"$file\"", HELP_LAUNCHER)


if __name__ == "__main__":
    unittest.main()
