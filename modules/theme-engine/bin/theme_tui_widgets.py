#!/usr/bin/env python3
"""Small curses widgets used by Theme Studio."""
from __future__ import annotations

import curses
from collections import OrderedDict
from dataclasses import dataclass
import re
from typing import Any, Iterable


@dataclass
class Palette:
    normal: int = 0
    accent: int = 0
    selected: int = 0
    muted: int = 0
    success: int = 0
    warning: int = 0
    error: int = 0
    panel: int = 0


_SWATCH_PAIRS: dict[int, int] = {}
_NEXT_SWATCH_PAIR = 16
_HEX_COLOR_RE = re.compile(r"#[0-9A-Fa-f]{6}")

_RGB_POOL_SIZE = 200
_RGB_PAIRS: "OrderedDict[str, int]" = OrderedDict()
_RGB_SLOTS_USED = 0
_TRUE_COLOR_SUPPORTED: bool | None = None


def init_palette() -> Palette:
    if not curses.has_colors():
        return Palette()
    curses.start_color()
    curses.use_default_colors()
    pairs = [
        (1, curses.COLOR_CYAN, -1),
        (2, curses.COLOR_BLACK, curses.COLOR_CYAN),
        (3, curses.COLOR_WHITE, -1),
        (4, curses.COLOR_GREEN, -1),
        (5, curses.COLOR_YELLOW, -1),
        (6, curses.COLOR_RED, -1),
        (7, curses.COLOR_MAGENTA, -1),
    ]
    for pair, fg, bg in pairs:
        try:
            curses.init_pair(pair, fg, bg)
        except curses.error:
            pass
    return Palette(
        normal=curses.color_pair(3),
        accent=curses.color_pair(1) | curses.A_BOLD,
        selected=curses.color_pair(2) | curses.A_BOLD,
        muted=curses.A_DIM,
        success=curses.color_pair(4),
        warning=curses.color_pair(5),
        error=curses.color_pair(6),
        panel=curses.color_pair(7) | curses.A_BOLD,
    )


def safe_addstr(win: Any, y: int, x: int, text: str, attr: int = 0, width: int | None = None) -> None:
    """Safely draw text and turn literal hex colors into visible color chips.

    Unselected text containing #RRGGBB is rendered as a small colored block plus
    the original hex value. This makes Palette Studio visually scannable instead
    of showing a wall of nearly identical white strings. Selected/highlighted
    rows keep the selection styling so keyboard navigation remains obvious.
    """
    try:
        h, w = win.getmaxyx()
        if y < 0 or y >= h or x < 0 or x >= w:
            return
        room = max(0, w - x - 1)
        if width is not None:
            room = min(room, max(0, width))
        rendered = str(text)
        matches = list(_HEX_COLOR_RE.finditer(rendered))
        if not matches or attr:
            win.addnstr(y, x, rendered, room, attr)
            return

        cursor = 0
        column = x
        used = 0
        for match in matches:
            if used >= room:
                break
            prefix = rendered[cursor:match.start()]
            if prefix:
                chunk = prefix[: max(0, room - used)]
                win.addnstr(y, column, chunk, max(0, room - used), attr)
                column += len(chunk)
                used += len(chunk)
            if used >= room:
                break

            value = match.group(0)
            color_attr = color_swatch_attr(value, win)
            chip = "███ " if color_attr else "■ "
            chip = chip[: max(0, room - used)]
            if chip:
                win.addnstr(y, column, chip, max(0, room - used), color_attr or attr)
                column += len(chip)
                used += len(chip)
            if used >= room:
                break

            hex_text = value[: max(0, room - used)]
            if hex_text:
                win.addnstr(y, column, hex_text, max(0, room - used), color_attr or attr)
                column += len(hex_text)
                used += len(hex_text)
            cursor = match.end()

        suffix = rendered[cursor:]
        if suffix and used < room:
            win.addnstr(y, column, suffix, room - used, attr)
    except curses.error:
        pass


def fill_line(win: Any, y: int, x: int, width: int, char: str = " ", attr: int = 0) -> None:
    safe_addstr(win, y, x, char * max(0, width), attr, width)


def draw_box(win: Any, y: int, x: int, height: int, width: int, title: str = "", attr: int = 0) -> None:
    if height < 2 or width < 4:
        return
    safe_addstr(win, y, x, "╭" + "─" * (width - 2) + "╮", attr, width)
    for row in range(1, height - 1):
        safe_addstr(win, y + row, x, "│", attr)
        safe_addstr(win, y + row, x + width - 1, "│", attr)
    safe_addstr(win, y + height - 1, x, "╰" + "─" * (width - 2) + "╯", attr, width)
    if title:
        label = f" {title} "
        safe_addstr(win, y, x + 2, label, attr | curses.A_BOLD, width - 4)


def draw_header(win: Any, title: str, right: str, palette: Palette) -> None:
    _, width = win.getmaxyx()
    fill_line(win, 0, 0, width - 1, " ", palette.panel)
    safe_addstr(win, 0, 1, f"✦ {title}", palette.panel, max(0, width - len(right) - 5))
    if right:
        safe_addstr(win, 0, max(1, width - len(right) - 2), right, palette.panel)
    safe_addstr(win, 1, 0, "─" * max(0, width - 1), palette.muted)


def draw_footer(win: Any, text: str, palette: Palette) -> None:
    height, width = win.getmaxyx()
    safe_addstr(win, height - 2, 0, "─" * max(0, width - 1), palette.muted)
    fill_line(win, height - 1, 0, width - 1, " ")
    safe_addstr(win, height - 1, 1, text, palette.muted, width - 3)


def draw_list(win: Any, y: int, x: int, height: int, width: int,
              items: Iterable[str], selected: int, palette: Palette,
              offset: int | None = None, markers: dict[int, str] | None = None) -> int:
    values = list(items)
    if not values:
        safe_addstr(win, y, x, "(none)", palette.muted, width)
        return 0
    visible = max(1, height)
    if offset is None:
        offset = max(0, min(selected - visible // 2, max(0, len(values) - visible)))
    for row, index in enumerate(range(offset, min(len(values), offset + visible))):
        marker = (markers or {}).get(index, "")
        text = f"{marker}{values[index]}"
        attr = palette.selected if index == selected else 0
        fill_line(win, y + row, x, width, " ", attr)
        safe_addstr(win, y + row, x, text, attr, width)
    return offset


def slider_text(value: float, minimum: float, maximum: float, width: int = 16,
                precision: int | None = None) -> str:
    if maximum <= minimum:
        ratio = 0.0
    else:
        ratio = (float(value) - minimum) / (maximum - minimum)
    ratio = max(0.0, min(1.0, ratio))
    knob = int(round(ratio * max(1, width - 1)))
    bar = "━" * knob + "●" + "━" * max(0, width - knob - 1)
    if precision is None:
        precision = 2 if isinstance(value, float) and not float(value).is_integer() else 0
    return f"{bar} {value:.{precision}f}"


def _parse_hex(value: str) -> tuple[int, int, int] | None:
    if not isinstance(value, str) or len(value) != 7 or not value.startswith("#"):
        return None
    try:
        return int(value[1:3], 16), int(value[3:5], 16), int(value[5:7], 16)
    except ValueError:
        return None


def _xterm256_from_hex(value: str) -> int | None:
    """Approximate a #RRGGBB value with the nearest xterm-256 color."""
    parsed = _parse_hex(value)
    if parsed is None:
        return None
    red, green, blue = parsed

    if max(red, green, blue) - min(red, green, blue) < 10:
        if red < 8:
            return 16
        if red > 248:
            return 231
        return 232 + max(0, min(23, round((red - 8) / 10)))

    def cube(value8: int) -> int:
        return max(0, min(5, round(value8 / 255 * 5)))

    return 16 + 36 * cube(red) + 6 * cube(green) + cube(blue)


def _supports_true_color() -> bool:
    """Detect whether the terminal can be reprogrammed with exact RGB values.

    Most modern terminals (kitty, alacritty, wezterm, foot, real xterm) expose
    an "initc"/"ccc" terminfo capability that lets ncurses redefine a palette
    slot to any RGB triple, instead of only picking the closest of the 216
    fixed xterm-256 cube colors. Using it makes swatches match Quickshell's
    true-color rendering instead of a washed-out approximation.
    """
    global _TRUE_COLOR_SUPPORTED
    if _TRUE_COLOR_SUPPORTED is None:
        _TRUE_COLOR_SUPPORTED = bool(
            curses.has_colors()
            and getattr(curses, "COLORS", 0) >= 256
            and curses.can_change_color()
        )
    return _TRUE_COLOR_SUPPORTED


_PALETTE_REPROGRAMMED = False


def _true_color_pair(value: str) -> int:
    """Map a hex value onto a small reused pool of true-color palette slots.

    Interactive widgets (the HSV picker sliders) redraw a new hex value on
    every keystroke. Handing out a brand-new permanent terminal palette slot
    per distinct hex exhausts the ~240 available slots within a second of
    dragging a slider; once exhausted, swatches silently fell back to the
    coarse xterm-256 cube approximation mid-drag, which reads as the color
    flashing correct and then reverting. Reusing a bounded LRU pool of slots
    (reprogramming the oldest one in place) keeps true color always active.

    Reprogramming a slot number that's already visible elsewhere on screen is
    itself risky: terminals recolor every on-screen glyph using that palette
    index the instant it's redefined, but ncurses only re-sends a cell's
    color-pair escape code when the cell's (char, pair-number) tuple differs
    from what it last physically sent. A long-lived session that cycles
    through many distinct colors (browsing themes, dragging sliders) reuses
    slot numbers for unrelated hexes; any older on-screen cell that still
    shows the same character with that same pair number - unchanged from
    curses' point of view - silently inherits the new color underneath it
    without ever being told to redraw, which reads as swatches going stale
    or "wrong" over time. `_PALETTE_REPROGRAMMED` flags this so callers can
    force a full window repaint (clearok) past that diff-based shortcut.
    """
    global _RGB_SLOTS_USED, _PALETTE_REPROGRAMMED
    if value in _RGB_PAIRS:
        _RGB_PAIRS.move_to_end(value)
        return curses.color_pair(_RGB_PAIRS[value])
    parsed = _parse_hex(value)
    if parsed is None:
        return 0
    color_limit = max(0, getattr(curses, "COLORS", 0) - 1)
    pair_limit = max(0, getattr(curses, "COLOR_PAIRS", 0) - 1)
    pool_size = min(_RGB_POOL_SIZE, color_limit - 15, pair_limit - 15)
    if pool_size <= 0:
        return 0
    if _RGB_SLOTS_USED < pool_size:
        slot = 16 + _RGB_SLOTS_USED
        _RGB_SLOTS_USED += 1
    else:
        _, slot = _RGB_PAIRS.popitem(last=False)
    red, green, blue = parsed
    try:
        curses.init_color(slot, round(red / 255 * 1000), round(green / 255 * 1000), round(blue / 255 * 1000))
        curses.init_pair(slot, slot, -1)
    except curses.error:
        return 0
    _RGB_PAIRS[value] = slot
    _PALETTE_REPROGRAMMED = True
    return curses.color_pair(slot)


def _resync_palette(win: Any) -> None:
    """Force a full repaint of `win` if any swatch slot was just reprogrammed."""
    global _PALETTE_REPROGRAMMED
    if _PALETTE_REPROGRAMMED and win is not None:
        try:
            win.clearok(True)
        except curses.error:
            pass
        _PALETTE_REPROGRAMMED = False


def color_swatch_attr(value: str, win: Any = None) -> int:
    """Return a curses attribute that renders close to the requested hex color."""
    global _NEXT_SWATCH_PAIR
    if not curses.has_colors() or getattr(curses, "COLORS", 0) < 256:
        return 0
    if _supports_true_color():
        attr = _true_color_pair(value)
        _resync_palette(win)
        if attr:
            return attr
    color = _xterm256_from_hex(value)
    if color is None:
        return 0
    if color in _SWATCH_PAIRS:
        return curses.color_pair(_SWATCH_PAIRS[color])

    pair_limit = max(0, getattr(curses, "COLOR_PAIRS", 0) - 1)
    if _NEXT_SWATCH_PAIR > pair_limit:
        return 0
    pair = _NEXT_SWATCH_PAIR
    _NEXT_SWATCH_PAIR += 1
    try:
        curses.init_pair(pair, color, -1)
    except curses.error:
        return 0
    _SWATCH_PAIRS[color] = pair
    return curses.color_pair(pair)


def draw_color_swatch(win: Any, y: int, x: int, value: str, width: int = 3) -> None:
    """Draw a compact terminal color chip with a graceful monochrome fallback."""
    attr = color_swatch_attr(value, win)
    if attr:
        safe_addstr(win, y, x, "█" * max(1, width), attr, width)
    else:
        safe_addstr(win, y, x, "■" * max(1, width), 0, width)


def role_swatch(value: str, width: int = 10) -> str:
    return f"{value:<{width}}"


def prompt(stdscr: Any, title: str, initial: str = "", max_length: int = 120,
           palette: Palette | None = None) -> str | None:
    palette = palette or Palette()
    height, width = stdscr.getmaxyx()
    box_w = min(max(34, len(title) + 8), max(34, width - 4))
    box_h = 7
    y = max(1, (height - box_h) // 2)
    x = max(1, (width - box_w) // 2)
    draw_box(stdscr, y, x, box_h, box_w, title, palette.accent)
    value = list(initial[:max_length])
    cursor = len(value)
    curses.curs_set(1)
    while True:
        fill_line(stdscr, y + 3, x + 2, box_w - 4)
        shown = "".join(value)
        start = max(0, cursor - (box_w - 8))
        safe_addstr(stdscr, y + 3, x + 2, shown[start:], 0, box_w - 4)
        safe_addstr(stdscr, y + 5, x + 2, "Enter confirm · Esc cancel", palette.muted, box_w - 4)
        try:
            stdscr.move(y + 3, x + 2 + min(cursor - start, box_w - 5))
        except curses.error:
            pass
        stdscr.refresh()
        key = stdscr.get_wch()
        if key in ("\n", "\r"):
            curses.curs_set(0)
            return "".join(value)
        if key == "\x1b":
            curses.curs_set(0)
            return None
        if key in (curses.KEY_BACKSPACE, "\b", "\x7f"):
            if cursor > 0:
                cursor -= 1
                value.pop(cursor)
        elif key == curses.KEY_DC:
            if cursor < len(value):
                value.pop(cursor)
        elif key == curses.KEY_LEFT:
            cursor = max(0, cursor - 1)
        elif key == curses.KEY_RIGHT:
            cursor = min(len(value), cursor + 1)
        elif key == curses.KEY_HOME:
            cursor = 0
        elif key == curses.KEY_END:
            cursor = len(value)
        elif isinstance(key, str) and key.isprintable() and len(value) < max_length:
            value.insert(cursor, key)
            cursor += 1


def confirm(stdscr: Any, title: str, message: str, palette: Palette | None = None,
            default: bool = False) -> bool:
    palette = palette or Palette()
    height, width = stdscr.getmaxyx()
    box_w = min(max(42, len(message) + 6), max(42, width - 4))
    box_h = 8
    y = max(1, (height - box_h) // 2)
    x = max(1, (width - box_w) // 2)
    draw_box(stdscr, y, x, box_h, box_w, title, palette.warning)
    safe_addstr(stdscr, y + 2, x + 2, message, 0, box_w - 4)
    choice = 0 if default else 1
    while True:
        labels = [" Yes ", " No "]
        total = sum(map(len, labels)) + 4
        start = x + max(2, (box_w - total) // 2)
        for idx, label in enumerate(labels):
            attr = palette.selected if idx == choice else 0
            safe_addstr(stdscr, y + 5, start, label, attr)
            start += len(label) + 4
        stdscr.refresh()
        key = stdscr.getch()
        if key in (curses.KEY_LEFT, curses.KEY_RIGHT, ord("h"), ord("l"), 9):
            choice = 1 - choice
        elif key in (10, 13):
            return choice == 0
        elif key in (27, ord("q")):
            return False
        elif key in (ord("y"), ord("Y")):
            return True
        elif key in (ord("n"), ord("N")):
            return False


def message(stdscr: Any, title: str, lines: Iterable[str], palette: Palette | None = None,
            attr: int = 0) -> None:
    palette = palette or Palette()
    values = list(lines)
    height, width = stdscr.getmaxyx()
    box_w = min(max(46, max((len(line) for line in values), default=0) + 6), max(46, width - 4))
    box_h = min(max(7, len(values) + 5), max(7, height - 2))
    y = max(1, (height - box_h) // 2)
    x = max(1, (width - box_w) // 2)
    draw_box(stdscr, y, x, box_h, box_w, title, palette.accent)
    for index, line in enumerate(values[: box_h - 4]):
        safe_addstr(stdscr, y + 2 + index, x + 2, line, attr, box_w - 4)
    safe_addstr(stdscr, y + box_h - 2, x + 2, "Press any key", palette.muted, box_w - 4)
    stdscr.refresh()
    stdscr.getch()
