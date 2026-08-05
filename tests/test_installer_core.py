from __future__ import annotations

import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from installer.runtime import manifest
from installer.state import StateStore


class ManifestTests(unittest.TestCase):
    def test_manifests_are_unique_and_comment_aware(self) -> None:
        for path in sorted((ROOT / "manifests").glob("packages-*.txt")):
            values = manifest(path)
            self.assertEqual(len(values), len(set(values)), path)
            self.assertTrue(values, path)
            self.assertTrue(all(" " not in value for value in values), path)

    def test_profiles_reference_existing_manifests(self) -> None:
        for path in sorted((ROOT / "installer/profiles").glob("*.json")):
            profile = json.loads(path.read_text(encoding="utf-8"))
            self.assertEqual(path.stem, profile["name"])
            self.assertTrue(profile["manifests"])
            for filename in profile["manifests"]:
                self.assertTrue((ROOT / "manifests" / filename).is_file(), filename)


class StateTests(unittest.TestCase):
    def test_backup_restore_and_created_path_ownership(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            state = StateStore(root / "state", root / "backups", "run-1")
            target = root / "config.txt"
            target.write_text("before\n", encoding="utf-8")
            state.backup_target(target)
            target.write_text("after\n", encoding="utf-8")

            created = root / "created.txt"
            created.write_text("owned\n", encoding="utf-8")
            state.record_created_path(created)

            actions = state.restore()
            self.assertEqual(target.read_text(encoding="utf-8"), "before\n")
            self.assertFalse(created.exists())
            self.assertTrue(any("restore" in action for action in actions))
            self.assertTrue(any("remove" in action for action in actions))

    def test_state_file_is_valid_json(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            state = StateStore(root / "state", root / "backups", "run-2")
            state.set_metadata(profile="desktop", theme="y2k")
            payload = json.loads(state.path.read_text(encoding="utf-8"))
            self.assertEqual(payload["schema_version"], 1)
            self.assertEqual(payload["profile"], "desktop")
            self.assertEqual(payload["theme"], "y2k")


class ThemeTests(unittest.TestCase):
    def test_theme_generates_all_consumers_atomically(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            config = root / "config"
            theme_dir = config / "theme-engine/themes"
            theme_dir.mkdir(parents=True)
            shutil.copy2(
                ROOT / "modules/theme-engine/themes/y2k.json",
                theme_dir / "y2k.json",
            )
            environment = os.environ.copy()
            environment["HOME"] = str(root / "home")
            environment["XDG_CONFIG_HOME"] = str(config)
            command = [sys.executable, str(ROOT / "modules/theme-engine/bin/theme"), "y2k"]
            result = subprocess.run(command, env=environment, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)

            contract = json.loads(
                (config / "theme-engine/generated/theme.json").read_text(encoding="utf-8")
            )
            self.assertEqual(contract["schema_version"], 1)
            self.assertEqual(contract["name"], "y2k")
            self.assertIs(contract["style"]["blur_on"], False)
            self.assertIn("surface_0", contract["roles"])
            self.assertEqual(contract["wallpaper"]["generator"], "wallgen")

            expected = (
                config / "hypr/generated/theme.lua",
                config / "hypr/generated/theme.conf",
                config / "kitty/generated/theme.conf",
                config / "theme-engine/generated/starship.toml",
                config / "nvim/lua/generated_theme.lua",
                config / "theme-engine/generated/.active",
            )
            for path in expected:
                self.assertTrue(path.is_file(), path)
                self.assertGreater(path.stat().st_size, 0, path)
            self.assertIn("hl.config", expected[0].read_text(encoding="utf-8"))
            self.assertIn("cursor", expected[2].read_text(encoding="utf-8"))

    def test_invalid_theme_does_not_replace_active_output(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            config = root / "config"
            theme_dir = config / "theme-engine/themes"
            generated = config / "theme-engine/generated"
            theme_dir.mkdir(parents=True)
            generated.mkdir(parents=True)
            active = generated / "theme.json"
            active.write_text('{"name":"known-good"}\n', encoding="utf-8")
            (theme_dir / "broken.json").write_text(
                '{"schema_version":1,"name":"broken","roles":{},"style":{}}\n',
                encoding="utf-8",
            )
            environment = os.environ.copy()
            environment["HOME"] = str(root / "home")
            environment["XDG_CONFIG_HOME"] = str(config)
            result = subprocess.run(
                [sys.executable, str(ROOT / "modules/theme-engine/bin/theme"), "broken"],
                env=environment,
                text=True,
                capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(active.read_text(encoding="utf-8"), '{"name":"known-good"}\n')


class ThemeCatalogTests(unittest.TestCase):
    @staticmethod
    def theme_payload(name: str) -> dict:
        return {
            "schema_version": 1,
            "name": name,
            "dark": True,
            "roles": {
                "bg": "#101010",
                "bg_alt": "#181818",
                "text": "#F0F0F0",
                "text_dim": "#A0A0A0",
                "focus": "#FF00AA",
                "border_normal": "#404040",
                "accent": "#00DDFF",
                "accent2": "#FF00AA",
                "urgent": "#FF3355",
            },
            "style": {"corner_radius": 8, "blur_on": False},
        }

    def test_pinned_catalog_installs_40_themes_and_preserves_custom_files(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            source = root / "source/themes"
            source.mkdir(parents=True)
            for index in range(40):
                name = f"theme-{index:02d}"
                (source / f"{name}.json").write_text(
                    json.dumps(self.theme_payload(name)) + "\n",
                    encoding="utf-8",
                )

            config = root / "config"
            installed = config / "theme-engine/themes"
            installed.mkdir(parents=True)
            custom = installed / "my-custom.json"
            custom.write_text(json.dumps(self.theme_payload("my-custom")) + "\n", encoding="utf-8")

            environment = os.environ.copy()
            environment["HOME"] = str(root / "home")
            environment["XDG_CONFIG_HOME"] = str(config)
            result = subprocess.run(
                [
                    sys.executable,
                    str(ROOT / "modules/theme-engine/bin/theme-catalog-sync"),
                    "--source",
                    str(root / "source"),
                ],
                env=environment,
                text=True,
                capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(len(list(installed.glob("theme-*.json"))), 40)
            self.assertTrue(custom.is_file())
            lock = json.loads(
                (config / "theme-engine/upstream-lock.json").read_text(encoding="utf-8")
            )
            self.assertEqual(lock["theme_count"], 40)
            self.assertEqual(
                lock["commit"],
                "c609410fbd88ddc2a15c51ab142743c49ae861e0",
            )
            self.assertEqual(len(lock["managed_files"]), 40)

    def test_catalog_rejects_incomplete_upstream(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            source = root / "source/themes"
            source.mkdir(parents=True)
            payload = self.theme_payload("only-one")
            (source / "only-one.json").write_text(json.dumps(payload) + "\n", encoding="utf-8")
            environment = os.environ.copy()
            environment["HOME"] = str(root / "home")
            environment["XDG_CONFIG_HOME"] = str(root / "config")
            result = subprocess.run(
                [
                    sys.executable,
                    str(ROOT / "modules/theme-engine/bin/theme-catalog-sync"),
                    "--source",
                    str(root / "source"),
                ],
                env=environment,
                text=True,
                capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("expected at least 40", result.stderr)
            self.assertFalse((root / "config/theme-engine/upstream-lock.json").exists())


if __name__ == "__main__":
    unittest.main()
