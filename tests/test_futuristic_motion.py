from __future__ import annotations

import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
BAR = ROOT / "modules/shell/surfaces/bar/BarSurface.qml"
DRAWER = ROOT / "modules/shell/surfaces/bar/DrawerSurface.qml"
LAUNCHER = ROOT / "modules/shell/surfaces/bar/LauncherOverlay.qml"
PRO_CARD = ROOT / "modules/shell/surfaces/homepage/ProCard.qml"
HYPR_ENTRY = ROOT / "modules/hyprland/config/hyprland.lua"
HYPR_MOTION = ROOT / "modules/hyprland/config/conf/motion.lua"
EFFECTS_PROFILE = ROOT / "modules/hyprland/config/scripts/effects-profile.py"


class FuturisticShellMotionTests(unittest.TestCase):
    def test_bar_keeps_direct_widget_hosts_and_layer_motion(self) -> None:
        content = BAR.read_text(encoding="utf-8")
        self.assertEqual(content.count("WidgetHost {"), 4)
        self.assertNotIn("BarMotionHost {", content)
        self.assertIn('WlrLayershell.namespace: root.isPrimary ? "arch-wm:bar"', content)
        self.assertIn("HoverHandler { id: menuHover }", content)
        self.assertIn("HoverHandler { id: homeHover }", content)
        self.assertIn("Core.UiStyle.quietButtons", content)
        self.assertIn("Behavior on scale", content)

    def test_drawer_and_launcher_have_internal_reveal_motion(self) -> None:
        drawer = DRAWER.read_text(encoding="utf-8")
        launcher = LAUNCHER.read_text(encoding="utf-8")
        self.assertIn("property real revealProgress", drawer)
        self.assertIn("drawerWindow.startReveal", drawer)
        self.assertIn("transform: Translate", drawer)
        self.assertIn("property real revealProgress", launcher)
        self.assertIn("launcherWindow.startReveal", launcher)
        # Precision suppresses the legacy zoom while Legacy keeps it. The test
        # validates the semantic switch instead of freezing one profile's math.
        self.assertIn("Core.UiStyle.quietButtons ? 1.0", launcher)
        self.assertIn("0.91 + launcherWindow.revealProgress * 0.09", launcher)
        self.assertIn("Core.UiStyle.radiusOverlay", launcher)
        self.assertIn('WlrLayershell.namespace: "arch-wm-launcher"', launcher)

    def test_hyprland_motion_loads_after_theme(self) -> None:
        content = HYPR_ENTRY.read_text(encoding="utf-8")
        theme_index = content.index('pcall(require, "generated.theme")')
        motion_index = content.index('require("conf.motion")')
        self.assertLess(theme_index, motion_index)

    def test_hyprland_motion_has_three_persisted_effect_profiles(self) -> None:
        content = HYPR_MOTION.read_text(encoding="utf-8")
        self.assertIn('"performance"', content)
        self.assertIn('"balanced"', content)
        self.assertIn('"cinematic"', content)
        self.assertIn('hypr/effects-profile', content)
        self.assertIn('ARCH_WM_EFFECTS_PROFILE', content)
        self.assertIn('ARCH_WM_LOW_MOTION', content)
        self.assertIn('profile = "performance"', content)

    def test_hyprland_motion_uses_055_safe_glow_shadow_and_focus_fades(self) -> None:
        content = HYPR_MOTION.read_text(encoding="utf-8")
        self.assertIn('type = "spring"', content)
        self.assertIn("dampening =", content)
        self.assertIn("shadow = {", content)
        self.assertIn("glow = {", content)
        self.assertIn("dim_inactive = effects_enabled", content)
        self.assertIn('"fadeSwitch", "fadeShadow", "fadeGlow", "fadeDim"', content)
        self.assertIn('leaf = "windowsIn"', content)
        self.assertIn('leaf = "windowsMove"', content)
        self.assertIn('leaf = "workspaces"', content)
        self.assertIn('leaf = "specialWorkspace"', content)
        self.assertIn('leaf = "layersIn"', content)
        self.assertIn('animation = "slide top"', content)
        self.assertIn('animation = "slide right"', content)

    def test_newer_effects_are_version_gated(self) -> None:
        content = HYPR_MOTION.read_text(encoding="utf-8")
        motion_gate = content.index("if effects_enabled and hypr_at_least(0, 56) then")
        motion_block = content.index("motion_blur = {", motion_gate)
        wobble_gate = content.index('ARCH_WM_EXPERIMENTAL_WOBBLE')
        wobble_version = content.index("hypr_at_least(0, 57)", wobble_gate)
        wobble_block = content.index("wobble = {", wobble_version)
        self.assertLess(motion_gate, motion_block)
        self.assertLess(wobble_gate, wobble_version)
        self.assertLess(wobble_version, wobble_block)

    def test_motion_layer_never_uses_continuous_angle_loops(self) -> None:
        content = HYPR_MOTION.read_text(encoding="utf-8")
        self.assertIn('leaf = "borderangle"', content)
        self.assertIn('style = "once"', content)
        self.assertNotIn('style = "loop"', content)
        self.assertNotIn('leaf = "glowangle"', content)

    def test_effects_profile_switcher_writes_profile_and_reloads(self) -> None:
        content = EFFECTS_PROFILE.read_text(encoding="utf-8")
        self.assertIn('{"performance", "balanced", "cinematic"}', content)
        self.assertIn('"hypr" / "effects-profile"', content)
        self.assertIn('["hyprctl", "reload"]', content)

    def test_professional_cards_have_profile_aware_hover_treatment(self) -> None:
        content = PRO_CARD.read_text(encoding="utf-8")
        self.assertIn("id: cardHover", content)
        self.assertIn("blocking: false", content)
        # Precision stays optically still; card-style profiles retain the
        # subtle legacy lift. Both paths must be driven by the UI contract.
        self.assertIn("Core.UiStyle.flatSurfaces ? 1.0", content)
        self.assertIn("cardHover.hovered && root.revealProgress >= 0.999 ? 1.006 : 1.0", content)
        self.assertIn("Behavior on color", content)
        self.assertIn("Behavior on scale", content)


if __name__ == "__main__":
    unittest.main()
