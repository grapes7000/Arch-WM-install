from __future__ import annotations

import unittest
from pathlib import Path


class NeovimOwnershipTests(unittest.TestCase):
    def test_desktop_repo_does_not_ship_a_second_nvim_config(self) -> None:
        root = Path(__file__).resolve().parents[1]
        self.assertFalse((root / "modules/nvim").exists())
        self.assertFalse((root / "scripts/install-nvim.sh").exists())

    def test_top_level_installer_does_not_overwrite_dotfiles_nvim(self) -> None:
        root = Path(__file__).resolve().parents[1]
        install = (root / "install.sh").read_text(encoding="utf-8")
        self.assertNotIn("install-nvim.sh", install)
        self.assertNotIn("modules/nvim", install)

    def test_theme_contract_can_still_target_nvim(self) -> None:
        root = Path(__file__).resolve().parents[1]
        theme = (root / "modules/theme-engine/bin/theme").read_text(encoding="utf-8")
        self.assertIn("nvim", theme)
        scanner = (root / "desktop_manager/scanner.py").read_text(encoding="utf-8")
        self.assertIn('("nvim",', scanner)


if __name__ == "__main__":
    unittest.main()
