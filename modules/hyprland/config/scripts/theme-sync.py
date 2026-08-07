#!/usr/bin/env python3
"""Apply universal theme appearance tokens to the running Hyprland session.

The theme engine remains the owner of appearance data. This Hyprland-side
translator watches generated/theme.json and maps shared style tokens to
compositor settings without putting workspace or window-rule policy in the
theme contract.
"""
from __future__ import annotations

import json
import os
import subprocess
import time
from pathlib import Path
from typing import Any

HOME = Path.home()
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config"))
THEME = CONFIG / "theme-engine/generated/theme.json"

PROFILES: dict[str, dict[str, Any]] = {
    "minimal": {"speed": 12, "curve": "linear", "pop": "100%"},
    "smooth": {"speed": 6, "curve": "archTheme", "pop": "94%"},
    "snappy": {"speed": 9, "curve": "archThemeFast", "pop": "96%"},
    "dramatic": {"speed": 4, "curve": "archThemeSoft", "pop": "88%"},
}


def run(*args: str) -> None:
    subprocess.run(
        ["hyprctl", *args],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )


def keyword(name: str, value: Any) -> None:
    if isinstance(value, bool):
        value = "true" if value else "false"
    run("keyword", name, str(value))


def load() -> dict[str, Any] | None:
    try:
        payload = json.loads(THEME.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    if payload.get("schema_version") != 1 or not isinstance(payload.get("style"), dict):
        return None
    return payload


def derived_profile(style: dict[str, Any]) -> str:
    explicit = str(style.get("animation_profile", "")).lower()
    if explicit in PROFILES:
        return explicit
    ms = int(style.get("animation_ms", 160) or 160)
    if ms <= 80:
        return "minimal"
    if ms <= 135:
        return "snappy"
    if ms >= 240:
        return "dramatic"
    return "smooth"


def apply(payload: dict[str, Any]) -> None:
    style = payload["style"]
    # window_gap is the canonical compositor spacing token. `gaps` remains a
    # compatibility fallback for the existing catalog, while bar_padding is a
    # shell-only geometry token and must never affect Hyprland window spacing.
    gaps = max(0, int(style.get("window_gap", style.get("gaps", 8))))
    radius = max(0, int(style.get("corner_radius", 8)))
    border = max(0, int(style.get("border_width", 2)))
    active_opacity = max(0.0, min(1.0, float(style.get("opacity", 1.0))))
    inactive_opacity = max(0.0, min(1.0, float(style.get("opacity_inactive", 0.96))))
    blur_on = bool(style.get("blur_on", True))
    shadow_on = bool(style.get("shadow_on", True))
    profile_name = derived_profile(style)
    profile = PROFILES[profile_name]
    motion_scale = max(0.0, min(2.0, float(style.get("motion_scale", 1.0))))
    workspace_style = str(style.get("workspace_animation", "slide"))
    if workspace_style not in {"slide", "slidevert", "fade"}:
        workspace_style = "slide"

    keyword("general:gaps_in", gaps // 2)
    keyword("general:gaps_out", gaps)
    keyword("general:border_size", border)
    keyword("decoration:rounding", radius)
    keyword("decoration:active_opacity", active_opacity)
    keyword("decoration:inactive_opacity", inactive_opacity)
    keyword("decoration:blur:enabled", blur_on)
    keyword("decoration:blur:size", max(1, int(style.get("blur_strength", 6))))
    keyword("decoration:blur:passes", max(1, int(style.get("blur_passes", 2))))
    keyword("decoration:shadow:enabled", shadow_on)
    keyword("decoration:shadow:range", max(0, int(style.get("shadow_radius", 20))))

    if motion_scale <= 0:
        keyword("animations:enabled", False)
        return

    keyword("animations:enabled", True)
    run("keyword", "bezier", "archTheme,0.16,1,0.3,1")
    run("keyword", "bezier", "archThemeFast,0.2,0.9,0.2,1")
    run("keyword", "bezier", "archThemeSoft,0.2,0.8,0.2,1")
    speed = max(1, round(profile["speed"] / motion_scale))
    run("keyword", "animation", f"windows,1,{speed},{profile['curve']},popin {profile['pop']}")
    run("keyword", "animation", f"windowsOut,1,{max(1, speed - 1)},{profile['curve']},popin {profile['pop']}")
    run("keyword", "animation", f"fade,1,{speed},{profile['curve']}")
    run("keyword", "animation", f"layers,1,{speed},{profile['curve']}")
    run("keyword", "animation", f"workspaces,1,{speed},{profile['curve']},{workspace_style}")


def main() -> int:
    last_stamp: tuple[int, int] | None = None
    while True:
        try:
            stat = THEME.stat()
            stamp = (stat.st_mtime_ns, stat.st_size)
        except OSError:
            stamp = None
        if stamp is not None and stamp != last_stamp:
            payload = load()
            if payload is not None:
                apply(payload)
                last_stamp = stamp
        time.sleep(1.5)


if __name__ == "__main__":
    raise SystemExit(main())
