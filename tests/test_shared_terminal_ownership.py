from __future__ import annotations

import inspect
import unittest

from installer import entry, runtime


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

    def test_entrypoint_does_not_replace_shared_theme_stage(self) -> None:
        source = inspect.getsource(entry.patch_runtime)
        self.assertNotIn('"40-theme-engine"', source)
        self.assertFalse(hasattr(entry, "theme_apply"))

    def test_entrypoint_has_no_legacy_terminal_payload_installer(self) -> None:
        source = inspect.getsource(entry)
        self.assertNotIn("modules/terminal", source)
        self.assertFalse(hasattr(entry, "theme_apply"))

    def test_arch_wm_help_is_session_integration_not_theme_ownership(self) -> None:
        self.assertIn("arch-wm/help.txt", inspect.getsource(entry.session_apply))
        self.assertIn("arch-wm-help", inspect.getsource(entry.session_apply))
        self.assertNotIn("arch-wm-help", inspect.getsource(runtime.theme_apply))

    def test_doctor_uses_shared_layer_contracts(self) -> None:
        source = inspect.getsource(entry.doctor_command)
        self.assertIn("standalone theme engine", source)
        self.assertIn("Chezmoi source", source)
        self.assertNotIn("theme studio payload", source)
        self.assertNotIn("terminal profile", source)

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
