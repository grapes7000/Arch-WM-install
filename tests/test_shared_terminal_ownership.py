from __future__ import annotations

import inspect
import unittest

from installer import runtime


class SharedTerminalOwnershipTests(unittest.TestCase):
    def test_theme_stage_does_not_install_portable_terminal_files(self) -> None:
        source = inspect.getsource(runtime.theme_apply)
        forbidden = (
            "modules/terminal",
            "kitty/kitty.conf",
            "zsh/.zshrc",
            "zsh/aliases.zsh",
            "atuin/config.toml",
            ".local/bin/term",
        )
        for value in forbidden:
            self.assertNotIn(value, source)

    def test_theme_check_only_requires_theme_engine_outputs(self) -> None:
        source = inspect.getsource(runtime.theme_check)
        self.assertIn(".local/bin/theme", source)
        self.assertIn("theme-engine/generated/theme.json", source)
        self.assertNotIn("kitty/kitty.conf", source)
        self.assertNotIn(".zshrc", source)
        self.assertNotIn("atuin/config.toml", source)

    def test_dotfiles_stage_remains_after_theme_and_desktop_stages(self) -> None:
        self.assertGreater(
            runtime.STAGE_ORDER.index("85-dotfiles"),
            runtime.STAGE_ORDER.index("40-theme-engine"),
        )
        self.assertGreater(
            runtime.STAGE_ORDER.index("85-dotfiles"),
            runtime.STAGE_ORDER.index("50-hyprland"),
        )


if __name__ == "__main__":
    unittest.main()
