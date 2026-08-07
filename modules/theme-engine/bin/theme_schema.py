"""Theme Studio quality checks for the shared Arch-WM theme contract.

These checks are advisory rather than schema errors: creative themes are still
allowed, but Theme Studio can surface combinations that tend to look washed
out, muddy, or visually flat before the user applies them.
"""
from __future__ import annotations

import colorsys
import json
from pathlib import Path
from typing import Any


def _rgb(value: str) -> tuple[float, float, float]:
    value = value.lstrip("#")
    if len(value) != 6:
        raise ValueError(value)
    return tuple(int(value[index:index + 2], 16) / 255.0 for index in (0, 2, 4))


def _linear(channel: float) -> float:
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4


def _luminance(value: str) -> float:
    red, green, blue = (_linear(channel) for channel in _rgb(value))
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue


def _contrast(left: str, right: str) -> float:
    high = max(_luminance(left), _luminance(right))
    low = min(_luminance(left), _luminance(right))
    return (high + 0.05) / (low + 0.05)


def _saturation(value: str) -> float:
    red, green, blue = _rgb(value)
    return colorsys.rgb_to_hsv(red, green, blue)[1]


def quality_warnings(payload: dict[str, Any]) -> list[str]:
    roles = payload.get("roles") or {}
    style = payload.get("style") or {}
    warnings: list[str] = []

    try:
        bg = str(roles["bg"])
        text = str(roles["text"])
        text_dim = str(roles.get("text_dim", text))
        accent = str(roles["accent"])
        accent2 = str(roles.get("accent2", accent))
        surface = str(roles.get("surface_1", roles.get("bg_alt", bg)))
        border = str(roles.get("border_subtle", roles.get("border_normal", surface)))

        if _contrast(bg, text) < 4.5:
            warnings.append("primary text/background contrast is below 4.5:1")
        if _contrast(bg, text_dim) < 3.0:
            warnings.append("muted text/background contrast is below 3:1")
        if _contrast(bg, surface) < 1.08:
            warnings.append("background and raised surface are too similar; cards may look flat")
        if _contrast(surface, border) < 1.10:
            warnings.append("surface and border are too similar; edges may disappear")
        if max(_saturation(accent), _saturation(accent2)) < 0.42:
            warnings.append("both accent colors are low-saturation; the theme may look washed out")
        if _contrast(bg, accent) < 1.55 and _contrast(surface, accent) < 1.55:
            warnings.append("primary accent has weak separation from both background and surface")
    except (KeyError, TypeError, ValueError):
        warnings.append("color quality checks could not read one or more theme roles")

    surface_opacity = float(style.get("surface_opacity", 0.96) or 0.96)
    if surface_opacity < 0.82:
        warnings.append("surface opacity is very low; stacked panels may look gray or washed out")

    bar_height = int(style.get("bar_height", 48) or 48)
    bar_padding = int(style.get("bar_padding", 8) or 0)
    if bar_padding * 2 > max(0, bar_height - 16):
        warnings.append("bar padding leaves less than 16px for bar content; Quickshell will clamp it")

    return warnings


def catalog_warnings(theme_dir: Path) -> list[tuple[str, list[str]]]:
    results: list[tuple[str, list[str]]] = []
    if not theme_dir.is_dir():
        return results
    for path in sorted(theme_dir.glob("*.json")):
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        warnings = quality_warnings(payload)
        if warnings:
            results.append((path.stem, warnings))
    return results
