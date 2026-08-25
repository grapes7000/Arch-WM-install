from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from desktop_manager.manager import DesktopManager, Paths
from desktop_manager.models import ProfileError
from desktop_manager.scanner import scan_tree


class ScannerTests(unittest.TestCase):
    def test_blocks_pam_and_symlink_escape(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "install.sh").write_text("sudo cp qs-lock /etc/pam.d/qs-lock\n", encoding="utf-8")
            (root / "escape").symlink_to("/etc/passwd")
            report = scan_tree(root)
            cats = {item["category"] for item in report["findings"]}
            self.assertEqual(report["verdict"], "blocked")
            self.assertIn("pam", cats)
            self.assertIn("symlink_escape", cats)

    def test_pure_comments_do_not_create_blockers(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "config.lua").write_text("-- docs mention /etc/sddm.conf only\n")
            report = scan_tree(root)
            self.assertEqual(report["blockers"], 0)

    def test_warns_for_protected_personal_config(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = root / "config/kitty/kitty.conf"
            path.parent.mkdir(parents=True)
            path.write_text("font_size 12\n", encoding="utf-8")
            report = scan_tree(root)
            self.assertTrue(any(item["category"] == "protected_config" for item in report["findings"]))


class ManagerTests(unittest.TestCase):
    def manager(self, temp: Path) -> DesktopManager:
        defs = temp / "defs"
        defs.mkdir()
        profile = {
            "id": "demo",
            "name": "Demo",
            "repository": "https://github.com/example/demo.git",
            "ref": "main",
            "kind": "hyprland-quickshell",
            "runtime": {"shell": "quickshell"},
            "config": [
                {"source": "config/hypr", "target": "hypr"},
                {"source": "config/quickshell", "target": "quickshell"},
            ],
            "protected": ["kitty"],
        }
        (defs / "demo.json").write_text(json.dumps(profile), encoding="utf-8")
        paths = Paths(
            home=temp / "home",
            config=temp / "home/.config",
            data_root=temp / "data",
            state_root=temp / "state",
            profile_defs=defs,
        )
        paths.home.mkdir()
        paths.config.mkdir(parents=True)
        source = paths.data_root / "sources/demo"
        (source / "config/hypr").mkdir(parents=True)
        (source / "config/quickshell").mkdir(parents=True)
        (source / "config/hypr/hyprland.conf").write_text("monitor=,preferred,auto,1\n")
        (source / "config/quickshell/shell.qml").write_text("import Quickshell\nShellRoot {}\n")
        return DesktopManager(paths)

    def test_prepare_copies_only_curated_mappings(self):
        with tempfile.TemporaryDirectory() as tmp:
            manager = self.manager(Path(tmp))
            source = manager.source_dir("demo")
            (source / "config/kitty").mkdir()
            (source / "config/kitty/kitty.conf").write_text("do not import\n")
            with patch.object(manager, "_git", return_value="deadbeef\n"), \
                 patch.object(manager, "_installed", return_value=True):
                lock = manager.prepare("demo", force_review=True)
            payload = manager.payload_dir("demo") / "config"
            self.assertTrue((payload / "hypr/hyprland.conf").is_file())
            self.assertTrue((payload / "quickshell/shell.qml").is_file())
            self.assertFalse((payload / "kitty").exists())
            self.assertEqual(lock["commit"], "deadbeef")

    def test_activation_refuses_inside_hyprland(self):
        with tempfile.TemporaryDirectory() as tmp:
            manager = self.manager(Path(tmp))
            with patch.dict(os.environ, {"HYPRLAND_INSTANCE_SIGNATURE": "abc"}):
                with self.assertRaises(ProfileError):
                    manager.activate_pending(apply=True)

    def test_arch_wm_snapshot_protects_unmanaged_config(self):
        with tempfile.TemporaryDirectory() as tmp:
            manager = self.manager(Path(tmp))
            hypr = manager.paths.config / "hypr"
            hypr.mkdir()
            (hypr / "mine.conf").write_text("mine\n")
            manager._ensure_arch_wm_snapshot()
            snap = manager.payload_dir("arch-wm") / "config/hypr/mine.conf"
            self.assertEqual(snap.read_text(), "mine\n")

    def test_audit_excludes_blockers_outside_curated_paths(self):
        with tempfile.TemporaryDirectory() as tmp:
            manager = self.manager(Path(tmp))
            source = manager.source_dir("demo")
            (source / "install.sh").write_text("sudo cp x /etc/pam.d/x\n", encoding="utf-8")
            report = manager.audit("demo")
            self.assertEqual(report["static"]["blockers"], 0)
            self.assertGreater(report["source_scan"]["blockers"], 0)
            self.assertTrue(any(item["category"] == "pam" for item in report["excluded_findings"]))

    def test_existing_qs_provider_is_reused(self):
        with tempfile.TemporaryDirectory() as tmp:
            manager = self.manager(Path(tmp))
            spec_path = manager.paths.profile_defs / "demo.json"
            data = json.loads(spec_path.read_text())
            data["official_packages"] = ["quickshell", "jq"]
            spec_path.write_text(json.dumps(data))
            with patch("desktop_manager.manager.shutil.which", side_effect=lambda name: "/usr/bin/qs" if name == "qs" else None), \
                 patch.object(manager, "_installed", return_value=False), \
                 patch.object(manager, "audit", return_value={"static": {"blockers": 0, "warnings": 0}}):
                plan = manager.plan("demo")
            self.assertNotIn("quickshell", plan["packages"]["missing_official"])
            self.assertIn("jq", plan["packages"]["missing_official"])
            self.assertTrue(plan["packages"]["quickshell_provider_reused"])

    def test_monitor_overlay_written_for_supported_adapter(self):
        with tempfile.TemporaryDirectory() as tmp:
            manager = self.manager(Path(tmp))
            spec_path = manager.paths.profile_defs / "demo.json"
            data = json.loads(spec_path.read_text())
            data["monitor_adapter"] = "tsugumori-user-lua"
            spec_path.write_text(json.dumps(data))
            payload = manager.payload_dir("demo") / "config/hypr"
            payload.mkdir(parents=True)
            manager._apply_monitor_snapshot("demo", [{
                "name": "DP-1", "width": 2560, "height": 1440,
                "refreshRate": 144.0, "x": 0, "y": 0, "scale": 1.0,
            }])
            user_lua = (payload / "user.lua").read_text()
            self.assertIn("DP-1", user_lua)
            self.assertIn("2560x1440@144", user_lua)


if __name__ == "__main__":
    unittest.main()
