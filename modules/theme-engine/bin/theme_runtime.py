<<<<<<< Updated upstream
"""Compatibility module reserved for the future Theme Studio runtime."""
=======
#!/usr/bin/env python3
"""Runtime bridge between the stable legacy generator and Theme Studio overrides."""
from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from typing import Any

from theme_components import apply_all
from theme_schema import dump_json, ensure_theme_schema, safe_theme_name

CFG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
THEME_DIR = CFG / "theme-engine" / "themes"
ACTIVE_FILE = CFG / "theme-engine" / "generated" / ".active"
PREVIEW_NAME = "_theme_studio_preview"
# The preview draft lives in the generated dir, never inside the themes dir,
# so it cannot surface as a selectable theme in browsers or managers.
PREVIEW_FILE = CFG / "theme-engine" / "generated" / f"{PREVIEW_NAME}.json"


def active_theme() -> str | None:
    try:
        value = ACTIVE_FILE.read_text(encoding="utf-8").strip()
        return value or None
    except OSError:
        return None


def legacy_command() -> list[str] | None:
    explicit = os.environ.get("THEME_LEGACY_COMMAND")
    if explicit:
        return explicit.split()
    found = shutil.which("theme-legacy")
    if found:
        return [found]
    sibling = Path(__file__).resolve().with_name("theme-legacy")
    if sibling.exists():
        return [str(sibling)]
    # Development checkout: original engine is named bin/theme while the studio
    # entry point is bin/theme-studio.
    source = Path(__file__).resolve().with_name("theme")
    if source.exists() and source.name != Path(sys.argv[0]).name:
        return [str(source)]
    return None


def load_theme(name: str) -> dict[str, Any]:
    path = THEME_DIR / f"{safe_theme_name(name)}.json"
    return ensure_theme_schema(json.loads(path.read_text(encoding="utf-8")))


def write_preview(data: dict[str, Any]) -> Path:
    PREVIEW_FILE.parent.mkdir(parents=True, exist_ok=True)
    path = PREVIEW_FILE
    fd, tmp_name = tempfile.mkstemp(prefix=".preview-", dir=str(path.parent), text=True)
    tmp = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(dump_json(ensure_theme_schema(data)))
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp, path)
    finally:
        tmp.unlink(missing_ok=True)
    return path


def cleanup_preview() -> None:
    PREVIEW_FILE.unlink(missing_ok=True)
    # Remove drafts left behind by versions that wrote into the themes dir.
    (THEME_DIR / f"{PREVIEW_NAME}.json").unlink(missing_ok=True)


def _run_legacy(name: str) -> tuple[bool, str]:
    command = legacy_command()
    if not command:
        return False, "legacy generator not found; applied Studio-managed components only"
    proc = subprocess.run(command + [name], text=True, capture_output=True)
    message = (proc.stdout or proc.stderr or "").strip()
    return proc.returncode == 0, message


def apply_studio_overrides(name: str, *,
                           components: list[str] | None = None) -> dict[str, Any]:
    """Apply only Studio-managed component layers after a legacy subcommand."""
    theme = load_theme(name)
    component_result = apply_all(theme, components)
    return {"name": name, "components": component_result}


def apply_theme(name: str, *, components: list[str] | None = None) -> dict[str, Any]:
    theme = load_theme(name)
    legacy_ok, legacy_message = _run_legacy(name)
    component_result = apply_all(theme, components)
    ACTIVE_FILE.parent.mkdir(parents=True, exist_ok=True)
    ACTIVE_FILE.write_text(name + "\n", encoding="utf-8")
    return {
        "name": name,
        "legacy_ok": legacy_ok,
        "legacy_message": legacy_message,
        "components": component_result,
    }


def _hyprland_reachable() -> bool:
    """True when a Hyprland instance is running and hyprctl can reach it.

    Trust HYPRLAND_INSTANCE_SIGNATURE when the caller was launched by the
    compositor, but fall back to probing `hyprctl instances` so previews still
    work from terminals that never inherited the variable.
    """
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        return True
    if not shutil.which("hyprctl"):
        return False
    try:
        proc = subprocess.run(["hyprctl", "instances"], capture_output=True,
                              text=True, timeout=5)
    except (OSError, subprocess.TimeoutExpired):
        return False
    return bool(proc.stdout and proc.stdout.strip())


def preview_theme(data: dict[str, Any], reason: str = "Preview") -> dict[str, Any]:
    """Live-preview a draft by rendering the Hyprland theme files directly.

    The legacy generator cannot round-trip Studio-schema drafts (its name
    matching rejects the preview name), so the old path never touched the
    file Hyprland actually loads. This renders generated/theme.conf and
    generated/theme.lua from the draft and reloads Hyprland on every change
    - no full apply, no wallpaper regeneration.
    """
    from theme_components import atomic_text, render_hypr, render_hypr_lua
    write_preview(data)
    theme = ensure_theme_schema(data)
    generated = CFG / "hypr" / "generated"
    generated.mkdir(parents=True, exist_ok=True)
    atomic_text(generated / "theme.conf", render_hypr(theme))
    atomic_text(generated / "theme.lua", render_hypr_lua(theme))
    if _hyprland_reachable():
        try:
            subprocess.run(["hyprctl", "reload"], check=False, timeout=5,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.TimeoutExpired:
            pass
    return {"name": PREVIEW_NAME, "reason": reason, "live": True}


def restore_theme(name: str) -> dict[str, Any]:
    cleanup_preview()
    return apply_theme(name)


def apply_saved_theme(name: str) -> dict[str, Any]:
    cleanup_preview()
    return apply_theme(name)
>>>>>>> Stashed changes
