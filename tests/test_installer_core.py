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
from installer.runtime import Context, Options
from installer.state import StateStore
from installer.entry import (
    THEME_COMMANDS,
    THEME_ENTRY_POINTS,
    THEME_STUDIO_MODULES,
    shell_check,
    theme_check,
    theme_payload_current,
)


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


class ThemeStudioDeliveryTests(unittest.TestCase):
    def test_delivery_layout_matches_theme_studio_docs(self) -> None:
        # The Studio owns `theme`; the legacy generator must be preserved as
        # `theme-legacy` and every Python module installed beside the entry point.
        self.assertNotIn("theme", THEME_COMMANDS)
        self.assertNotIn("theme-legacy", THEME_COMMANDS)
        self.assertIn(("theme-studio", "theme"), THEME_ENTRY_POINTS)
        self.assertIn(("theme", "theme-legacy"), THEME_ENTRY_POINTS)
        self.assertGreaterEqual(len(THEME_STUDIO_MODULES), 8)
        source_bin = ROOT / "modules/theme-engine/bin"
        self.assertTrue((source_bin / "theme-studio").is_file())
        for source_name, _ in THEME_ENTRY_POINTS:
            self.assertTrue((source_bin / source_name).is_file(), source_name)
        for module in THEME_STUDIO_MODULES:
            self.assertTrue((source_bin / module).is_file(), module)

    def test_installed_theme_route_applies_via_legacy_and_studio(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            bin_dir = root / "bin"
            bin_dir.mkdir(parents=True)
            source_bin = ROOT / "modules/theme-engine/bin"
            # Mirror entry.py's theme_apply payload: studio -> theme, legacy
            # generator -> theme-legacy, Python modules beside them.
            shutil.copy2(source_bin / "theme-studio", bin_dir / "theme")
            shutil.copy2(source_bin / "theme", bin_dir / "theme-legacy")
            for module in THEME_STUDIO_MODULES:
                shutil.copy2(source_bin / module, bin_dir / module)
            (bin_dir / "theme").chmod(0o755)
            (bin_dir / "theme-legacy").chmod(0o755)
            # The legacy generator resolves python via `env python3`; provide a
            # shim inside the isolated PATH so reload helpers stay unavailable.
            os.symlink(sys.executable, bin_dir / "python3")

            config = root / "config"
            theme_dir = config / "theme-engine/themes"
            theme_dir.mkdir(parents=True)
            shutil.copy2(ROOT / "modules/theme-engine/themes/y2k.json", theme_dir / "y2k.json")

            environment = os.environ.copy()
            environment["HOME"] = str(root / "home")
            environment["XDG_CONFIG_HOME"] = str(config)
            environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
            environment.pop("THEME_LEGACY_COMMAND", None)
            # Isolate PATH so reload helpers (kitty, dunstctl, hyprctl) are
            # never signalled during the hermetic apply.
            environment["PATH"] = str(bin_dir)

            result = subprocess.run(
                [sys.executable, str(bin_dir / "theme"), "y2k"],
                env=environment,
                text=True,
                capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            # Legacy generator ran first (writes the base contract) ...
            contract = json.loads(
                (config / "theme-engine/generated/theme.json").read_text(encoding="utf-8")
            )
            self.assertEqual(contract["name"], "y2k")
            self.assertEqual(
                (config / "theme-engine/generated/.active").read_text(encoding="utf-8").strip(),
                "y2k",
            )
            # ... then Studio component overrides were layered on top.
            lua = (config / "hypr/generated/theme.lua").read_text(encoding="utf-8")
            self.assertIn("hl.config", lua)
            self.assertIn("Theme Studio overrides applied", result.stdout)

class ThemeStageCheckTests(unittest.TestCase):
    def test_theme_check_rejects_stale_stub_payload(self) -> None:
        # Regression: an older install with stub placeholder modules satisfies
        # every is_file() check but must still trigger a 40-theme-engine re-apply.
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            environment = {
                "HOME": str(root / "home"),
                "XDG_CONFIG_HOME": str(root / "config"),
                "XDG_DATA_HOME": str(root / "data"),
                "XDG_STATE_HOME": str(root / "state"),
            }
            previous = {key: os.environ.get(key) for key in environment}
            os.environ.update(environment)
            try:
                config = pathlib.Path(os.environ["XDG_CONFIG_HOME"])
                bin_dir = pathlib.Path(os.environ["HOME"]) / ".local/bin"
                bin_dir.mkdir(parents=True)

                # Valid theme catalog (mirrors the pinned upstream state).
                theme_dir = config / "theme-engine/themes"
                theme_dir.mkdir(parents=True)
                payloads = ThemeCatalogTests.theme_payload
                for index in range(40):
                    (theme_dir / f"theme-{index:02d}.json").write_text(
                        json.dumps(payloads(f"theme-{index:02d}")) + "\n",
                        encoding="utf-8",
                    )
                (config / "theme-engine/upstream-lock.json").write_text(
                    json.dumps(
                        {
                            "commit": "c609410fbd88ddc2a15c51ab142743c49ae861e0",
                            "theme_count": 40,
                            "managed_files": [],
                        }
                    ),
                    encoding="utf-8",
                )

                # Stale payload: every delivered file exists but is a stub, and
                # the version marker is absent (older install layout).
                for name in (
                    *(installed for _, installed in THEME_ENTRY_POINTS),
                    *THEME_COMMANDS,
                    *THEME_STUDIO_MODULES,
                    "term",
                    "arch-wm-help",
                ):
                    (bin_dir / name).write_text("stale stub\n", encoding="utf-8")
                for path in (
                    pathlib.Path(os.environ["HOME"]) / ".zshrc",
                    config / "zsh/aliases.zsh",
                    config / "kitty/kitty.conf",
                    config / "atuin/config.toml",
                    config / "theme-engine/generated/theme.json",
                    config / "arch-wm/help.txt",
                ):
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text("{}\n", encoding="utf-8")

                options = Options(command="install", dry_run=True)
                context = Context(ROOT, options)
                self.assertFalse(theme_check(context))
                self.assertFalse(theme_payload_current(context))

                # A real apply delivers the real entry point and the current
                # version marker; together they flip the check to satisfied.
                shutil.copy2(
                    ROOT / "modules/theme-engine/bin/theme-studio",
                    bin_dir / "theme",
                )
                (config / "theme-engine/.arch-wm-version").write_text(
                    (ROOT / "modules/theme-engine/.arch-wm-version").read_text(
                        encoding="utf-8"
                    ),
                    encoding="utf-8",
                )
                self.assertTrue(theme_check(context))
            finally:
                for key, value in previous.items():
                    if value is None:
                        os.environ.pop(key, None)
                    else:
                        os.environ[key] = value


class ShellStageCheckTests(unittest.TestCase):
    def test_shell_check_rejects_payload_drift_even_with_matching_version(self) -> None:
        # Regression: shell_check used to trust modules/shell/.arch-wm-version
        # alone, which must be bumped by hand on every QML change. Commits
        # 7fb14c6 and 3dfa1aa (wallpaper symlink + media widget crash fixes)
        # landed without bumping it, so a real installer run would have seen
        # a matching version marker and skipped redeploying those fixes even
        # though the installed QML no longer matched the repo.
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            environment = {
                "HOME": str(root / "home"),
                "XDG_CONFIG_HOME": str(root / "config"),
                "XDG_DATA_HOME": str(root / "data"),
                "XDG_STATE_HOME": str(root / "state"),
            }
            previous = {key: os.environ.get(key) for key in environment}
            os.environ.update(environment)
            try:
                config = pathlib.Path(os.environ["XDG_CONFIG_HOME"])
                target = config / "quickshell/arch-wm"
                shutil.copytree(ROOT / "modules/shell", target)

                options = Options(command="install", dry_run=True)
                context = Context(ROOT, options)
                self.assertTrue(shell_check(context))

                # Simulate drift: repo QML changed but the version marker
                # was never bumped, matching what actually happened.
                (target / "core/Theme.qml").write_text(
                    "// stale copy, pre-dates the real fix\n", encoding="utf-8"
                )
                self.assertTrue(
                    (target / ".arch-wm-version").read_text(encoding="utf-8")
                    == (ROOT / "modules/shell/.arch-wm-version").read_text(
                        encoding="utf-8"
                    )
                )
                self.assertFalse(shell_check(context))
            finally:
                for key, value in previous.items():
                    if value is None:
                        os.environ.pop(key, None)
                    else:
                        os.environ[key] = value


if __name__ == "__main__":
    unittest.main()
