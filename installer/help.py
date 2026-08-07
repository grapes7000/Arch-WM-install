"""On-system quick reference: keybinds and important file locations.

The installer renders a plain-text reference from the exact keybind source
that gets installed (``~/.config/hypr/conf/keybinds.lua``) and from the paths
the installer itself manages. The rendered text is installed to
``~/.config/arch-wm/help.txt`` and printed by the ``arch-wm-help`` launcher,
which the managed zsh aliases expose as ``help``.

``./install.sh help`` (or ``python -m installer help``) prints the same
reference from a development checkout.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Sequence

from . import runtime

# Loop-generated binds in keybinds.lua are documented by expanding the loop
# bodies. Order follows the file; descriptions are synthesized from the loop
# semantics and the explicit `description` fields.
_DIRECTION_KEYS = ("H", "J", "K", "L", "left", "down", "up", "right")
_SPECIAL_KEYS = ("Z", "N", "C")
# `for workspace = 1, 10` with `local key = workspace % 10` produces 1..9, 0.
_WORKSPACE_KEYS = tuple(str(index % 10) for index in range(1, 11))
_WORKSPACE_NUMBERS = tuple(str(index) for index in range(1, 11))

_BIND_RE = re.compile(r"hl\.bind\s*\(")
_DESCRIPTION_RE = re.compile(r'description\s*=\s*([^,}\n]+)')
_MAIN_RE = re.compile(r'\blocal\s+main\s*=\s*"([^"]*)"')
_ENTRY_RE = re.compile(r'\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"([^"]*)"')

_MOUSE_LABELS = (
    ("mouse:273", "Right Mouse"),
    ("mouse:272", "Left Mouse"),
    ("mouse_down", "Scroll Down"),
    ("mouse_up", "Scroll Up"),
)

# The config registers the media keys without descriptions; label them here.
_MEDIA_LABELS = {
    "XF86AudioRaiseVolume": "Raise volume",
    "XF86AudioLowerVolume": "Lower volume",
    "XF86AudioMute": "Mute audio",
    "XF86AudioMicMute": "Mute microphone",
    "XF86AudioPlay": "Play/pause media",
    "XF86AudioPause": "Play/pause media",
    "XF86AudioNext": "Next track",
    "XF86AudioPrev": "Previous track",
    "XF86MonBrightnessUp": "Increase brightness",
    "XF86MonBrightnessDown": "Decrease brightness",
}

_COMMANDS = (
    ("help", "print this reference (alias for arch-wm-help)"),
    ("arch-wm-help", "print this reference"),
    ("theme", "open Theme Studio to pick a theme (theme <name> applies directly)"),
    ("term", "launch the managed terminal"),
    ("reload-shell", "restart the shell with fresh config"),
)

# The on-system launcher. It only prints the generated reference file, so the
# rendered text stays in sync with the installed configuration on every run.
HELP_LAUNCHER = """#!/usr/bin/env sh
# Managed by Arch WM Install. Prints the desktop quick reference (keybinds
# and important file locations). Regenerated on every installer run.
file="${XDG_CONFIG_HOME:-$HOME/.config}/arch-wm/help.txt"
if [ ! -r "$file" ]; then
  echo "Arch WM reference missing: $file" >&2
  echo "Re-run the installer to regenerate it." >&2
  exit 1
fi
cat "$file"
"""


def _table_entries(text: str, name: str) -> list[tuple[str, str]]:
    """Return (key, value) pairs of a `local <name> = { ... }` table in order."""
    match = re.search(
        rf"\blocal\s+{re.escape(name)}\s*=\s*\{{(.*?)\}}", text, re.S
    )
    if not match:
        return []
    entries: list[tuple[str, str]] = []
    for line in match.group(1).splitlines():
        entry = _ENTRY_RE.match(line)
        if entry:
            entries.append((entry.group(1), entry.group(2)))
    return entries


def _scan_until(text: str, opener: int) -> int | None:
    """Return the index of the bracket closing the one that opens at `opener`."""
    depth = 0
    quote: str | None = None
    escaped = False
    for index in range(opener, len(text)):
        char = text[index]
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            continue
        if char in "\"'":
            quote = char
            continue
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
            if depth == 0:
                return index
    return None


def _loop_end(text: str, after_header: int) -> int | None:
    """Return the position of the `end` that closes a `for ... do` loop."""
    depth = 0
    for match in re.finditer(r"\bend\b", text[after_header:]):
        depth += 1
        if depth == 1:
            return after_header + match.start()
    return None


def _key_expression(call: str) -> str:
    """Return the key expression of an hl.bind(...) call (before first top-level comma)."""
    depth = 0
    quote: str | None = None
    escaped = False
    for index, char in enumerate(call):
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            continue
        if char in "\"'":
            quote = char
            continue
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == "," and depth == 1:
            return call[1:index].strip()
    return call[1:-1].strip()


def _concat(expression: str, main_key: str) -> str:
    """Evaluate a simple Lua string-concatenation expression."""
    parts: list[str] = []
    for token in expression.split(" .. "):
        token = token.strip()
        if len(token) >= 2 and token[0] == token[-1] == '"':
            parts.append(token[1:-1])
        elif token == "main":
            parts.append(main_key)
        else:
            parts.append(token)
    return "".join(parts)


def _evaluate_description(expression: str, loop_value: str | None, main_key: str) -> str:
    """Evaluate a description value: a literal or a small concat expression."""
    expression = expression.strip()
    if not expression:
        return ""
    if expression.startswith('"') and expression.endswith('"') and expression.count('"') == 2:
        return expression[1:-1]
    if loop_value is not None:
        # Substitute only the bare loop-variable token, never occurrences of
        # the same word inside string literals ("... special workspace").
        tokens = expression.split(" .. ")
        tokens = [
            f'"{loop_value}"' if token.strip() == "workspace" else token
            for token in tokens
        ]
        expression = " .. ".join(tokens)
    return _concat(expression, main_key)


def _expand_key(
    expression: str,
    main_key: str,
    keys: Sequence[str] | None,
    values: Sequence[str] | None = None,
) -> list[tuple[str, str, str | None]]:
    """Expand a key expression into (raw_key, rendered_key, loop_value) triples."""
    if not keys:
        rendered = _concat(expression, main_key)
        return [(rendered, _humanize(rendered), None)]
    expanded: list[tuple[str, str, str | None]] = []
    for key, value in zip(keys, values or keys):
        substituted = expression.replace("main", main_key).replace("key", str(key))
        rendered = _concat(substituted, main_key)
        expanded.append((str(key), _humanize(rendered), value))
    return expanded


def _humanize(key: str) -> str:
    for token, label in _MOUSE_LABELS:
        key = key.replace(token, label)
    return key.replace("Return", "Enter")


def _synthesize_description(
    kind: str | None,
    key: str,
    call: str,
    explicit: str,
    directions: dict[str, str],
) -> str:
    if explicit:
        return explicit
    media_label = _MEDIA_LABELS.get(key)
    if media_label:
        return media_label
    if "mouse_down" in key:
        return "Next workspace"
    if "mouse_up" in key:
        return "Previous workspace"
    if "mouse:272" in key:
        return "Drag window"
    if "mouse:273" in key:
        return "Resize window"
    if kind == "directions":
        direction = directions.get(key, key)
        if "window.move" in call:
            return f"Move window {direction}"
        return f"Focus window {direction}"
    if kind == "workspaces":
        number = 10 if key == "0" else int(key)
        if "window.move" in call:
            return f"Move window to workspace {number}"
        return f"Go to workspace {number}"
    return ""


def parse_keybinds(text: str) -> list[tuple[str, str]]:
    """Extract (keybinding, description) pairs from the Hyprland keybinds file.

    Loop-generated binds are expanded; identical rendered keys are deduplicated
    keeping the first occurrence (SUPER + L is bound twice in the config).
    """
    text = re.sub(r"--[^\n]*", "", text)
    main_key = "SUPER"
    main_match = _MAIN_RE.search(text)
    if main_match:
        main_key = main_match.group(1)

    directions = dict(_table_entries(text, "directions"))
    direction_keys = tuple(directions) or _DIRECTION_KEYS
    special = dict(_table_entries(text, "special_workspaces"))
    special_keys = tuple(special) or _SPECIAL_KEYS

    loops: list[tuple[int, int, str, tuple[str, ...], tuple[str, ...]]] = []
    for kind, pattern, keys, values in (
        (
            "directions",
            r"for\s+key,\s*direction\s+in\s+pairs\(directions\)\s+do",
            direction_keys,
            tuple(directions.get(key, key) for key in direction_keys),
        ),
        (
            "workspaces",
            r"for\s+workspace\s*=\s*1,\s*10\s+do",
            _WORKSPACE_KEYS,
            _WORKSPACE_NUMBERS,
        ),
        (
            "special",
            r"for\s+key,\s*workspace\s+in\s+pairs\(special_workspaces\)\s+do",
            special_keys,
            tuple(special.get(key, key) for key in special_keys),
        ),
    ):
        for header in re.finditer(pattern, text):
            end = _loop_end(text, header.end())
            if end is not None:
                loops.append((header.end(), end, kind, keys, values))

    binds: list[tuple[str, str]] = []
    seen: set[str] = set()
    for match in _BIND_RE.finditer(text):
        close = _scan_until(text, match.end() - 1)
        if close is None:
            continue
        call = text[match.end() - 1 : close + 1]
        description_match = _DESCRIPTION_RE.search(call)
        description_expression = description_match.group(1) if description_match else ""

        kind: str | None = None
        loop_keys: tuple[str, ...] | None = None
        loop_values: tuple[str, ...] | None = None
        for start, end, loop_kind, keys, values in loops:
            if start <= match.start() < end:
                kind, loop_keys, loop_values = loop_kind, keys, values
                break

        for raw_key, rendered, loop_value in _expand_key(
            _key_expression(call), main_key, loop_keys, loop_values
        ):
            if rendered in seen:
                continue
            seen.add(rendered)
            explicit = _evaluate_description(description_expression, loop_value, main_key)
            description = _synthesize_description(kind, raw_key, call, explicit, directions)
            if description:
                binds.append((rendered, description))
    return binds


def keybind_source(ctx: runtime.Context) -> Path:
    """Prefer the installed keybinds so the reference matches what is live."""
    installed = ctx.config / "hypr/conf/keybinds.lua"
    if installed.is_file():
        return installed
    return ctx.root / "modules/hyprland/config/conf/keybinds.lua"


def _display(path: Path, home: Path) -> str:
    """Render a path with ~ for the home prefix, keeping it readable."""
    try:
        return "~/" + str(path.relative_to(home))
    except ValueError:
        return str(path)


def file_locations(ctx: runtime.Context) -> list[tuple[str, str]]:
    """Important user-visible paths managed by the installer."""
    home = ctx.home
    config = ctx.config
    entries = (
        (config / "hypr", "Hyprland compositor config: keybinds, autostart, monitors, window rules"),
        (config / "hypr/hyprland.lua", "Hyprland entry config sourced at login"),
        (config / "hypr/wallpapers", "Generated wallpaper per theme (<theme>.png)"),
        (config / "quickshell/arch-wm", "Shell UI sources: bar, launcher, drawers, widgets"),
        (config / "quickshell/arch-wm/layouts", "Bar/desktop/lockscreen layout JSON; move widgets between surfaces here"),
        (config / "quickshell/homepage-images", "Homepage slideshow images; drop PNG/JPG/WEBP files here"),
        (config / "theme-engine/generated/theme.json", "Active theme contract consumed by shell, Hyprland, kitty, nvim, starship"),
        (config / "theme-engine/themes", "Installed theme catalog (40+ themes; switch with `theme`)"),
        (config / "theme-engine/generated/starship.toml", "Prompt theme generated from the active theme"),
        (config / "kitty/kitty.conf", "Terminal config"),
        (config / "kitty/generated/theme.conf", "Terminal colors generated from the active theme"),
        (config / "zsh/aliases.zsh", "Shell aliases and helper functions"),
        (config / "environment.d/90-arch-wm.conf", "Session environment (Wayland flags)"),
        (config / "arch-wm/session-example.zprofile", "Example TTY1 autostart (installer never edits ~/.zprofile)"),
        (config / "arch-wm/help.txt", "This reference, regenerated on each installer run"),
        (home / ".zshrc", "Shell profile; personal overrides go in ~/.zshrc.local"),
        (home / ".local/bin", "Installed helper commands: theme, term, arch-wm-help"),
        (ctx.state_root / "logs", "Installer run logs"),
        (ctx.backup_root, "Backups of replaced files, restored by uninstall"),
        (home / "Pictures/Screenshots", "Screenshots (Print or SUPER + S)"),
    )
    return [(_display(path, home), purpose) for path, purpose in entries]


def render_reference(
    ctx: runtime.Context,
    *,
    keybinds: Sequence[tuple[str, str]] | None = None,
) -> str:
    """Render the on-system quick reference text."""
    if keybinds is None:
        keybinds = parse_keybinds(keybind_source(ctx).read_text(encoding="utf-8"))

    width = 46
    lines = ["Arch WM quick reference", "=" * width, ""]

    lines.append("KEYBINDS")
    lines.append("-" * width)
    key_width = min(max((len(key) for key, _ in keybinds), default=0), 24)
    for key, description in keybinds:
        lines.append(f"  {key:<{key_width}}  {description}")
    lines.append("")

    lines.append("IMPORTANT FILE LOCATIONS")
    lines.append("-" * width)
    for path, purpose in file_locations(ctx):
        lines.append(f"  {path}")
        lines.append(f"    {purpose}")
    lines.append("")

    lines.append("QUICK COMMANDS")
    lines.append("-" * width)
    command_width = max(len(command) for command, _ in _COMMANDS)
    for command, purpose in _COMMANDS:
        lines.append(f"  {command:<{command_width}}  {purpose}")
    return "\n".join(lines) + "\n"


def help_command(ctx: runtime.Context) -> int:
    """The installer `help` subcommand: print the quick reference from the repo."""
    print(render_reference(ctx), end="")
    return 0
