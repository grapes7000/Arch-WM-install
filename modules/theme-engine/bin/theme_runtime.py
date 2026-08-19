#!/usr/bin/env python3
"""Runtime bridge between the stable legacy generator and Theme Studio overrides."""
from __future__ import annotations

import configparser
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
HOME = Path.home()
CACHE = Path(os.environ.get("XDG_CACHE_HOME", HOME / ".cache"))
THEME_DIR = CFG / "theme-engine" / "themes"
ACTIVE_FILE = CFG / "theme-engine" / "generated" / ".active"
RENDER_ROOT = CACHE / "theme-engine" / "wallpapers"
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
    source = Path(__file__).resolve().with_name("theme")
    if source.exists() and source.name != Path(sys.argv[0]).name:
        return [str(source)]
    return None


def wallgen_command() -> list[str] | None:
    explicit = os.environ.get("THEME_WALLGEN_COMMAND")
    if explicit:
        return explicit.split()
    found = shutil.which("wallgen")
    if found:
        return [found]
    sibling = Path(__file__).resolve().with_name("wallgen")
    if sibling.exists():
        return [str(sibling)]
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
    (THEME_DIR / f"{PREVIEW_NAME}.json").unlink(missing_ok=True)


def _run_legacy(name: str) -> tuple[bool, str]:
    command = legacy_command()
    if not command:
        return False, "legacy generator not found"
    try:
        proc = subprocess.run(command + [name], text=True, capture_output=True, timeout=20)
    except subprocess.TimeoutExpired:
        return False, "legacy generator timed out"
    stdout = (proc.stdout or "").strip()
    stderr = (proc.stderr or "").strip()
    if proc.returncode != 0:
        detail = stderr or stdout or f"legacy generator exited {proc.returncode}"
        return False, detail
    return True, stdout or stderr


def _atomic_symlink(target: Path, link: Path) -> None:
    target = target.expanduser().resolve()
    link.parent.mkdir(parents=True, exist_ok=True)
    temporary = link.with_name(f".{link.name}.{os.getpid()}.tmp")
    temporary.unlink(missing_ok=True)
    try:
        os.symlink(str(target), temporary)
        os.replace(temporary, link)
    finally:
        temporary.unlink(missing_ok=True)


def _publish_current_wallpaper(rendered: Path) -> tuple[Path, Path]:
    rendered = rendered.expanduser().resolve()
    if not rendered.is_file():
        raise OSError(f"rendered wallpaper does not exist: {rendered}")
    current = RENDER_ROOT / "current.png"
    homepage = CFG / "quickshell" / "homepage-images" / "theme-wallpaper.png"
    _atomic_symlink(rendered, current)
    _atomic_symlink(current, homepage)
    return current, homepage


def _sync_semantic_wallpaper(name: str) -> tuple[bool, str]:
    if name == PREVIEW_NAME:
        return False, ""
    command = wallgen_command()
    if not command:
        return False, ""
    try:
        proc = subprocess.run(command + ["semantic", "apply", name, "--set"], text=True, capture_output=True, timeout=20)
    except subprocess.TimeoutExpired:
        return False, "wallgen semantic apply timed out"
    message = (proc.stdout or proc.stderr or "").strip()
    if proc.returncode != 0:
        return False, message
    if message:
        rendered = Path(message.splitlines()[-1].strip())
        try:
            _publish_current_wallpaper(rendered)
        except OSError as exc:
            return False, f"{message}\ncurrent wallpaper link: {exc}"
    return True, message


# ── Application adapters ────────────────────────────────────────────
def _atomic_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=str(path.parent), text=True)
    tmp = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp, path)
    finally:
        tmp.unlink(missing_ok=True)


def _ensure_line(path: Path, line: str) -> None:
    text = path.read_text(encoding="utf-8") if path.is_file() else ""
    if line in text:
        return
    if text and not text.endswith("\n"):
        text += "\n"
    _atomic_text(path, text + line + "\n")


def _ensure_css_import(path: Path, line: str) -> None:
    text = path.read_text(encoding="utf-8") if path.is_file() else ""
    lines = [existing for existing in text.splitlines() if existing.strip() != line]
    insert_at = 0
    for index, existing in enumerate(lines):
        stripped = existing.strip()
        if not stripped:
            continue
        if stripped.lower().startswith("@charset"):
            insert_at = index + 1
        break
    lines.insert(insert_at, line)
    _atomic_text(path, "\n".join(lines) + "\n")


def _mozilla_roots() -> list[Path]:
    return [
        HOME / ".mozilla/firefox",
        CFG / "mozilla/firefox",
        HOME / ".librewolf",
        HOME / ".floorp",
        HOME / ".waterfox",
        HOME / ".mozilla/icecat",
        HOME / ".zen",
        CFG / "zen",
        HOME / ".var/app/org.mozilla.firefox/.mozilla/firefox",
        HOME / ".var/app/io.gitlab.librewolf-community/.librewolf",
        HOME / ".var/app/one.ablaze.floorp/.floorp",
    ]


def _profiles_from_ini(root: Path) -> list[Path]:
    ini = root / "profiles.ini"
    if not ini.is_file():
        return []
    parser = configparser.RawConfigParser()
    try:
        parser.read(ini, encoding="utf-8")
    except (configparser.Error, OSError):
        return []
    found: list[Path] = []
    for section in parser.sections():
        if not section.lower().startswith("profile"):
            continue
        raw = parser.get(section, "Path", fallback="").strip()
        if not raw:
            continue
        relative = parser.getboolean(section, "IsRelative", fallback=True)
        profile = (root / raw) if relative else Path(raw).expanduser()
        if profile.is_dir():
            found.append(profile.resolve())
    return found


def _firefox_profiles() -> list[Path]:
    profiles: set[Path] = set()
    for root in _mozilla_roots():
        if not root.is_dir():
            continue
        profiles.update(_profiles_from_ini(root))
        try:
            children = list(root.iterdir())
        except OSError:
            continue
        for child in children:
            if child.is_dir() and (
                "default" in child.name.lower()
                or (child / "prefs.js").is_file()
                or (child / "places.sqlite").is_file()
            ):
                profiles.add(child.resolve())
    return sorted(profiles)


def _apply_firefox(theme: dict[str, Any]) -> int:
    r = theme["roles"]
    css = f'''/* AUTO-GENERATED by Arch-WM `theme`. */
:root {{
  --toolbar-bgcolor: {r['bg']} !important;
  --toolbar-color: {r['text']} !important;
  --lwt-accent-color: {r['bg']} !important;
  --lwt-text-color: {r['text']} !important;
  --toolbar-field-background-color: {r['bg_alt']} !important;
  --toolbar-field-color: {r['text']} !important;
  --toolbar-field-focus-background-color: {r['surface_1']} !important;
  --toolbar-field-focus-color: {r['text']} !important;
}}
#navigator-toolbox, #nav-bar, #TabsToolbar {{
  background-color: {r['bg']} !important;
  color: {r['text']} !important;
}}
.tab-background[selected] {{ background-color: {r['bg_alt']} !important; }}
.tabbrowser-tab {{ color: {r['text_dim']} !important; }}
.tabbrowser-tab[selected] {{ color: {r['accent']} !important; }}
#urlbar-background {{ background-color: {r['bg_alt']} !important; }}
#urlbar {{ color: {r['text']} !important; }}
:root {{ --focus-outline-color: {r['focus']} !important; }}
'''
    profiles = _firefox_profiles()
    for profile in profiles:
        chrome = profile / "chrome"
        chrome.mkdir(parents=True, exist_ok=True)
        _atomic_text(chrome / "theme-engine.css", css)
        _ensure_css_import(chrome / "userChrome.css", '@import url("theme-engine.css");')
        _ensure_line(profile / "user.js", 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);')
    return len(profiles)


def _obsidian_vaults() -> list[Path]:
    registries = [
        CFG / "obsidian/obsidian.json",
        HOME / ".var/app/md.obsidian.Obsidian/config/obsidian/obsidian.json",
    ]
    vaults: set[Path] = set()
    for registry in registries:
        if not registry.is_file():
            continue
        try:
            data = json.loads(registry.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        raw_vaults = data.get("vaults", {}) if isinstance(data, dict) else {}
        if not isinstance(raw_vaults, dict):
            continue
        for entry in raw_vaults.values():
            if not isinstance(entry, dict) or not isinstance(entry.get("path"), str):
                continue
            vault = Path(entry["path"]).expanduser()
            if (vault / ".obsidian").is_dir():
                vaults.add(vault.resolve())
    return sorted(vaults)


def _apply_obsidian(theme: dict[str, Any]) -> int:
    r = theme["roles"]
    css = f'''/* AUTO-GENERATED by Arch-WM `theme`. */
body {{
  --background-primary: {r['bg']};
  --background-primary-alt: {r['bg_alt']};
  --background-secondary: {r['surface_1']};
  --background-secondary-alt: {r['surface_2']};
  --text-normal: {r['text']};
  --text-muted: {r['text_dim']};
  --text-accent: {r['accent']};
  --text-accent-hover: {r['accent2']};
  --interactive-accent: {r['accent']};
  --interactive-accent-hover: {r['accent2']};
  --interactive-normal: {r['surface_1']};
  --interactive-hover: {r['hover']};
  --background-modifier-border: {r['border_subtle']};
  --background-modifier-border-focus: {r['border_strong']};
  --text-selection: {r['accent']}40;
  --text-error: {r['urgent']};

  /* Obsidian gives active/focused window chrome its own palette. Keep the
     titlebar and tab strip on the Arch-WM semantic colors in both states. */
  --titlebar-background: {r['surface_1']};
  --titlebar-background-focused: {r['surface_1']};
  --titlebar-text-color: {r['text_dim']};
  --titlebar-text-color-focused: {r['text']};
  --tab-container-background: {r['surface_1']};
  --tab-background-active: {r['bg_alt']};
  --tab-text-color: {r['text_dim']};
  --tab-text-color-active: {r['text']};
  --tab-text-color-focused: {r['text']};
  --tab-text-color-focused-active: {r['accent']};
}}

/* Some Obsidian versions/themes put explicit backgrounds on these chrome
   elements instead of relying only on variables. Keep them synchronized too. */
.titlebar,
.workspace-tab-header-container {{
  background-color: {r['surface_1']} !important;
}}
body.is-focused .titlebar,
body.is-focused .workspace-tab-header-container {{
  background-color: {r['surface_1']} !important;
}}
'''
    applied = 0
    for vault in _obsidian_vaults():
        config = vault / ".obsidian"
        _atomic_text(config / "snippets/theme-engine.css", css)
        appearance = config / "appearance.json"
        try:
            data = json.loads(appearance.read_text(encoding="utf-8")) if appearance.is_file() else {}
        except (OSError, json.JSONDecodeError):
            continue
        if not isinstance(data, dict):
            continue
        snippets = data.get("enabledCssSnippets", [])
        if not isinstance(snippets, list):
            snippets = []
        if "theme-engine" not in snippets:
            snippets.append("theme-engine")
        data["enabledCssSnippets"] = snippets
        _atomic_text(appearance, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
        applied += 1
    return applied


def _apply_app_themes(theme: dict[str, Any]) -> dict[str, Any]:
    firefox = _apply_firefox(theme)
    obsidian = _apply_obsidian(theme)
    return {
        "firefox_profiles": firefox,
        "firefox_restart_required": bool(firefox),
        "obsidian_vaults": obsidian,
    }


def apply_studio_overrides(name: str, *, components: list[str] | None = None) -> dict[str, Any]:
    theme = load_theme(name)
    component_result = apply_all(theme, components)
    return {"name": name, "components": component_result}


def apply_theme(name: str, *, components: list[str] | None = None) -> dict[str, Any]:
    theme = load_theme(name)
    legacy_ok, legacy_message = _run_legacy(name)
    if not legacy_ok:
        raise RuntimeError("legacy theme generator failed" + (f": {legacy_message}" if legacy_message else ""))
    wallpaper_ok, wallpaper_message = _sync_semantic_wallpaper(name)
    component_result = apply_all(theme, components)
    app_result = _apply_app_themes(theme)
    ACTIVE_FILE.parent.mkdir(parents=True, exist_ok=True)
    ACTIVE_FILE.write_text(name + "\n", encoding="utf-8")
    return {
        "name": name,
        "legacy_ok": legacy_ok,
        "legacy_message": legacy_message,
        "wallpaper_ok": wallpaper_ok,
        "wallpaper_message": wallpaper_message,
        "components": component_result,
        "apps": app_result,
    }


def _hyprland_reachable() -> bool:
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        return True
    if not shutil.which("hyprctl"):
        return False
    try:
        proc = subprocess.run(["hyprctl", "instances"], capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.TimeoutExpired):
        return False
    return bool(proc.stdout and proc.stdout.strip())


def _sync_quickshell_contract(theme: dict[str, Any]) -> None:
    from theme_components import GENERATED_THEME_JSON, atomic_text
    try:
        existing = json.loads(GENERATED_THEME_JSON.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        existing = {}
    if not isinstance(existing, dict):
        existing = {}
    payload = dict(existing)
    payload["roles"] = theme["roles"]
    payload["style"] = {**existing.get("style", {}), **theme["style"]}
    payload["components"] = theme.get("components", existing.get("components", {}))
    payload["dark"] = bool(theme.get("dark", existing.get("dark", True)))
    payload.setdefault("schema_version", 1)
    payload.setdefault("name", theme.get("name", PREVIEW_NAME))
    GENERATED_THEME_JSON.parent.mkdir(parents=True, exist_ok=True)
    atomic_text(GENERATED_THEME_JSON, json.dumps(payload, indent=2) + "\n")


def preview_theme(data: dict[str, Any], reason: str = "Preview") -> dict[str, Any]:
    from theme_components import atomic_text, render_hypr, render_hypr_lua
    write_preview(data)
    theme = ensure_theme_schema(data)
    generated = CFG / "hypr" / "generated"
    generated.mkdir(parents=True, exist_ok=True)
    atomic_text(generated / "theme.conf", render_hypr(theme))
    atomic_text(generated / "theme.lua", render_hypr_lua(theme))
    _sync_quickshell_contract(theme)
    if _hyprland_reachable():
        try:
            subprocess.run(["hyprctl", "reload"], check=False, timeout=5, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.TimeoutExpired:
            pass
    return {"name": PREVIEW_NAME, "reason": reason, "live": True}


def restore_theme(name: str) -> dict[str, Any]:
    cleanup_preview()
    return apply_theme(name)


def apply_saved_theme(name: str) -> dict[str, Any]:
    cleanup_preview()
    return apply_theme(name)
