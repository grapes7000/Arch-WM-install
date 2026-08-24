# Theme Studio

`theme` now opens a keyboard-first desktop theme studio while preserving the existing CLI through `theme-legacy`.

## Install

```bash
git switch agent/theme-studio-tui
./install.sh
theme
```

The installer keeps the previous engine at `~/.local/bin/theme-legacy`, installs Theme Studio as `~/.local/bin/theme`, and installs the new Python modules beside it. Every legacy command still passes through unchanged.

## Main workflow

```text
Home → Quick Style → Component rooms → Advanced Inspector
```

- **Quick Style** exposes palette, shape, texture, spacing, borders, density, and animation.
- **Component rooms** expose Windows, notifications, terminal, prompt, lock screen, homepage, and app styling.
- **Palette Studio** supports role editing, locking, swapping, variants, contrast reports, and import/export.
- **Wallpaper Studio** extracts a palette with Pillow and creates an editable theme draft.
- **Advanced Inspector** exposes every stored value and its generated effect.
- **Shell Style** (Home screen) browses, live-edits, and creates Quickshell UI styles
  (`precision`/`legacy`/`win95`-type metrics and patterns). Edits write straight through to
  `~/.config/theme-engine/generated/ui-style.json`, which `modules/shell/core/UiStyle.qml`
  file-watches and reloads live — so changes are visible on the shell as you tweak them, before
  you decide to save. This is a separate artifact from `theme.json` and unrelated to the
  "Shell" component room (which edits Quickshell bar/card colors and sizing as part of a theme).
  Bundled styles can't be overwritten directly; editing one prompts a save-as into your
  user-custom catalog at `~/.config/theme-engine/ui-styles/custom/`.

## Safety model

- Changes live in memory until saved.
- Mock previews never reload the desktop.
- Live desktop preview writes a temporary theme and restores the original on cancel.
- Undo and redo are available throughout an editing session.
- Recovery drafts are written only after the first real change.
- Saves are atomic and existing themes are backed up under `~/.local/state/theme-studio/backups/`.
- Built-in themes default to **Save As** using a `_custom` suffix.

## Keyboard map

| Key | Action |
|---|---|
| Arrows / HJKL | Navigate or adjust |
| Enter | Open or edit |
| Space | Toggle temporary desktop preview |
| Tab | Switch simple/detail view or pane |
| `/` | Search all settings |
| `u` | Undo |
| `Ctrl+r` | Redo |
| `s` | Save |
| `p` | Presets or Palette Studio, depending on screen |
| `a` | Advanced Inspector |
| `r` | Reset current room |
| `?` | Context help |
| `Esc` | Back |

## Commands

```bash
theme                      # Theme Studio
theme studio               # Theme Studio
theme edit sakura          # Open a specific theme
theme validate             # Validate active theme
theme validate sakura      # Validate named theme
theme catppuccin_mocha     # Apply through legacy engine + Studio overrides
theme legacy --list        # Run previous engine directly
```

## Bar and launcher styling

Theme Studio does not manage the Quickshell bar layout or the launcher surface — those are deliberately left to the hand-authored configs. The stable legacy generator themes the Quickshell shell, Hyprland, Kitty, Starship, and Neovim from the theme palette on every full apply.

## Pushing new themes to your real themes repo

`theme-new` and Theme Studio's "Create a new theme" save both write into
`~/.config/theme-engine/themes/`, which is populated by `theme-catalog-sync` from a *pinned commit*
of the upstream catalog — that directory is not itself a git checkout. To also get brand-new themes
mirrored into your actual pushable clone (e.g. a local checkout of `grapes7000/themes`), point at it
once:

```bash
echo ~/Projects/setup/themes > ~/.config/theme-engine/source-repo.conf
```

From then on, every newly created theme (not edits to existing catalog themes) is copied into
`<that path>/themes/<name>.json` too, ready for `git add`/`commit`/`push`. Leaving this file unset
or pointing at a missing path is fine — mirroring is skipped silently.

## Data model

Old theme JSON files continue to work. They are migrated in memory to schema version 3 with optional `components` and `studio` sections. Legacy `style` keys are synchronized automatically so old generators remain compatible.

```json
{
  "roles": { "bg": "#17131a", "accent": "#ff5aa5" },
  "style": {
    "spacing_preset": "cozy",
    "shape_preset": "soft",
    "texture_preset": "frosted",
    "border_preset": "gradient",
    "animation_preset": "smooth"
  },
  "components": {
    "windows": { "gaps_in": 5, "gaps_out": 10 }
  }
}
```

## Validation

```bash
PYTHONPATH=bin python -m unittest discover -s tests -p 'test_theme_studio.py' -v
bash -n install.sh
python -m py_compile bin/theme-studio bin/theme_*.py
```
