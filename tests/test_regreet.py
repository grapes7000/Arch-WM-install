from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
ADAPTER = ROOT / "modules/login/bin/arch-wm-regreet-theme"


class ReGreetTests(unittest.TestCase):
    def test_adapter_publishes_theme_css_and_wallpaper(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = root / "config"
            output = root / "output"
            contract = config / "theme-engine/generated/theme.json"
            wallpaper = config / "hypr/wallpapers/test.png"
            contract.parent.mkdir(parents=True)
            wallpaper.parent.mkdir(parents=True)
            wallpaper.write_bytes(b"png-data")
            contract.write_text(json.dumps({
                "name": "test",
                "roles": {
                    "bg": "#101112", "bg_alt": "#202122", "text": "#f0f1f2",
                    "text_dim": "#a0a1a2", "accent": "#00aaff", "urgent": "#ff3355",
                },
                "style": {"corner_radius": 9, "border_width": 2},
            }), encoding="utf-8")
            env = os.environ.copy()
            env.update({
                "HOME": str(root), "XDG_CONFIG_HOME": str(config),
                "XDG_CACHE_HOME": str(root / "cache"),
                "ARCH_WM_GREETD_ASSET_DIR": str(output),
            })
            result = subprocess.run(
                [sys.executable, str(ADAPTER), "--once"], env=env,
                text=True, capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            css = (output / "regreet.css").read_text(encoding="utf-8")
            self.assertIn("#101112", css)
            self.assertIn("#00aaff", css)
            self.assertIn("border-radius: 9px", css)
            self.assertEqual((output / "background.png").read_bytes(), b"png-data")

    def test_greetd_uses_cage_and_generated_style(self) -> None:
        config = (ROOT / "modules/login/greetd/config.toml").read_text(encoding="utf-8")
        self.assertIn("dbus-run-session cage", config)
        self.assertIn("/var/lib/arch-wm-greeter/regreet.css", config)
        self.assertIn('user = "greeter"', config)

    def test_login_packages_are_in_the_hyprland_manifest(self) -> None:
        manifest = (ROOT / "manifests/packages-hyprland.txt").read_text(encoding="utf-8")
        for package in ("greetd", "greetd-regreet", "cage"):
            self.assertIn(f"\n{package}\n", "\n" + manifest)

    def test_login_is_an_explicit_installer_stage(self) -> None:
        from installer import runtime
        self.assertIn("75-login", runtime.STAGE_ORDER)
        self.assertIn("75-login", [stage.name for stage in runtime.STAGES])


if __name__ == "__main__":
    unittest.main()
