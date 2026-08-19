from __future__ import annotations

import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
BAR = ROOT / "modules/shell/surfaces/bar/BarSurface.qml"
BAR_HOST = ROOT / "modules/shell/surfaces/bar/BarMotionHost.qml"
DRAWER = ROOT / "modules/shell/surfaces/bar/DrawerSurface.qml"
LAUNCHER = ROOT / "modules/shell/surfaces/bar/LauncherOverlay.qml"
HYPR_ENTRY = ROOT / "modules/hyprland/config/hyprland.lua"
HYPR_MOTION = ROOT / "modules/hyprland/config/conf/motion.lua"


class FuturisticShellMotionTests(unittest.TestCase):
    def test_bar_uses_animated_hosts_and_layer_namespace(self) -> None:
        content = BAR.read_text(encoding="utf-8")
        self.assertGreaterEqual(content.count("BarMotionHost {"), 4)
        self.assertIn('WlrLayershell.namespace: root.isPrimary ? "arch-wm:bar"', content)
        self.assertIn("HoverHandler { id: menuHover }", content)
        self.assertIn("HoverHandler { id: homeHover }", content)

    def test_bar_motion_is_layout_safe_and_reduced_motion_aware(self) -> None:
        content = BAR_HOST.read_text(encoding="utf-8")
        self.assertIn("revealProgress", content)
        self.assertIn("entranceOrder * 34", content)
        self.assertIn("HoverHandler", content)
        self.assertIn("Translate", content)
        self.assertIn("Core.Theme.motionScale <= 0.05", content)
        self.assertNotIn('property: "x"', content)
        self.assertNotIn('property: "y"', content)

    def test_drawer_and_launcher_have_internal_reveal_motion(self) -> None:
        drawer = DRAWER.read_text(encoding="utf-8")
        launcher = LAUNCHER.read_text(encoding="utf-8")
        self.assertIn("property real revealProgress", drawer)
        self.assertIn("drawerWindow.startReveal", drawer)
        self.assertIn("transform: Translate", drawer)
        self.assertIn("property real revealProgress", launcher)
        self.assertIn("launcherWindow.startReveal", launcher)
        self.assertIn("scale: 0.91 + launcherWindow.revealProgress * 0.09", launcher)
        self.assertIn('WlrLayershell.namespace: "arch-wm-launcher"', launcher)

    def test_hyprland_motion_loads_after_theme(self) -> None:
        content = HYPR_ENTRY.read_text(encoding="utf-8")
        theme_index = content.index('pcall(require, "generated.theme")')
        motion_index = content.index('require("conf.motion")')
        self.assertLess(theme_index, motion_index)

    def test_hyprland_motion_uses_055_compatible_spring_and_layer_features(self) -> None:
        content = HYPR_MOTION.read_text(encoding="utf-8")
        self.assertIn('type = "spring"', content)
        self.assertIn("dampening =", content)
        self.assertIn('leaf = "windowsIn"', content)
        self.assertIn('leaf = "windowsMove"', content)
        self.assertIn('leaf = "workspaces"', content)
        self.assertIn('leaf = "specialWorkspace"', content)
        self.assertIn('leaf = "layersIn"', content)
        self.assertIn('animation = "slide top"', content)
        self.assertIn('animation = "slide right"', content)
        self.assertIn('animation = "popin 94%"', content)

        # These compositor options landed after the 0.55 baseline and caused
        # live config errors on the VM. Keep them out until version-gated.
        self.assertNotIn("motion_blur", content)
        self.assertNotIn("wobble = {", content)
        self.assertNotIn('leaf = "glowangle"', content)

    def test_motion_layer_never_uses_continuous_angle_loops(self) -> None:
        content = HYPR_MOTION.read_text(encoding="utf-8")
        self.assertIn('leaf = "borderangle"', content)
        self.assertIn('style = "once"', content)
        self.assertNotIn('style = "loop"', content)
        self.assertIn('ARCH_WM_LOW_MOTION', content)


if __name__ == "__main__":
    unittest.main()
