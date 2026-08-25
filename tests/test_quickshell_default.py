from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "modules/hyprland/config/scripts/ensure-quickshell-default.sh"
AUTOSTART = ROOT / "modules/hyprland/config/conf/autostart.lua"


class QuickshellDefaultTests(unittest.TestCase):
    def run_helper(self, config_home: Path) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env["XDG_CONFIG_HOME"] = str(config_home)
        return subprocess.run(
            ["sh", str(HELPER)],
            env=env,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_creates_relative_default_alias_and_is_idempotent(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp)
            arch_wm = config_home / "quickshell/arch-wm"
            arch_wm.mkdir(parents=True)

            first = self.run_helper(config_home)
            self.assertEqual(first.returncode, 0, first.stderr)

            default = config_home / "quickshell/default"
            self.assertTrue(default.is_symlink())
            self.assertEqual(os.readlink(default), "arch-wm")

            second = self.run_helper(config_home)
            self.assertEqual(second.returncode, 0, second.stderr)
            self.assertEqual(os.readlink(default), "arch-wm")

    def test_refuses_to_overwrite_an_existing_default(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            config_home = Path(tmp)
            (config_home / "quickshell/arch-wm").mkdir(parents=True)
            existing = config_home / "quickshell/default"
            existing.mkdir()
            marker = existing / "keep-me"
            marker.write_text("user owned\n", encoding="utf-8")

            result = self.run_helper(config_home)
            self.assertNotEqual(result.returncode, 0)
            self.assertTrue(marker.is_file())
            self.assertFalse(existing.is_symlink())

    def test_autostart_uses_plain_qs_with_safe_named_fallback(self) -> None:
        text = AUTOSTART.read_text(encoding="utf-8")
        self.assertIn("ensure-quickshell-default.sh", text)
        self.assertIn("qs --no-duplicate;", text)
        self.assertIn("qs --no-duplicate --config arch-wm", text)


if __name__ == "__main__":
    unittest.main()
