# Automatic Application Theming Plan

## Goal

Extend the Arch-WM theme engine so `theme <name>` can safely propagate the active semantic palette into supported desktop applications without overwriting unrelated user settings.

The newer Arch-WM engine remains the source of truth. Proven optional adapters from `grapes7000/themes` should be ported into this engine rather than requiring a second theme runtime.

## Current state

Core Arch-WM targets are:

- Hyprland
- Quickshell
- Kitty
- Starship
- wallpaper
- Neovim

The older `grapes7000/themes` implementation already contains useful adapters for:

- Firefox-family browsers (`userChrome.css` + pywalfox palette)
- Obsidian CSS snippets
- VSCodium color customizations
- Alacritty imports
- Qt5/Qt6 via qt5ct/qt6ct
- KDE color schemes
- GTK/Oomox/Papirus integration

`theme-install` already advertises optional compatibility targets such as `gtk`, `kde`, `firefox`, and `obsidian=<vault>`, but these should become first-class Arch-WM adapters.

## Design rules

1. **Never replace whole user config files when a generated include/snippet is possible.**
2. **Back up once before the first mutation.** Generated files themselves do not need repeated backups.
3. **Generated files live under a clearly named `theme-engine` path or use an unmistakable generated filename.**
4. **App discovery is automatic but applying an adapter is deterministic and idempotent.**
5. **Profiles/vaults are discovered from application metadata, not fragile filename globs where a structured source exists.**
6. **Theme switching must not install browser extensions, modify accounts, or touch application data.**
7. **Each adapter owns only visual keys it generated.** It must preserve unrelated settings.
8. **A failed optional adapter must not prevent the core desktop theme from applying.** Failures are reported at the end.
9. **Flatpak/native installs are handled separately when their config paths differ.**
10. **Every adapter gets fixture-based tests before it becomes an auto-enabled target.**

## Architecture

Split application adapters out of the monolithic `theme` command:

```text
modules/theme-engine/bin/
  theme
  theme_apps/
    __init__.py
    firefox.py
    thunderbird.py
    obsidian.py
    vscode.py
    gtk.py
    qt.py
    alacritty.py
    discord.py        # later / optional
    spotify.py        # later / optional
```

Each adapter exposes a small contract:

```python
id = "firefox"

def detect() -> list[Target]: ...
def render(theme_contract, target) -> list[GeneratedFile]: ...
def apply(theme_contract, target) -> Result: ...
def reload(target) -> Result: ...
```

The main theme engine resolves the semantic theme once, writes `~/.config/theme-engine/generated/theme.json`, then sends that same contract to every enabled adapter.

## Target configuration

Keep `~/.config/theme-engine/targets.conf`, but add an automatic layer.

Proposed syntax:

```text
hypr
quickshell
kitty
starship
wallpaper
nvim
apps=auto

# Optional overrides:
# firefox=off
# thunderbird=on
# obsidian=auto
# gtk=on
# qt=on
```

`apps=auto` enables only adapters whose applications/configuration are detected. Explicit per-app entries override auto detection.

Add:

```bash
theme targets
theme targets detect
theme targets enable firefox
theme targets disable firefox
theme targets status
```

`status` should explain *why* an adapter is or is not active.

## Phase 1 — Firefox-family browsers

Port the existing `gen_firefox` behavior first, but improve profile discovery.

Supported initially:

- Firefox
- LibreWolf
- Floorp
- Waterfox
- Zen Browser
- Mullvad Browser only if its profile is user-writable and persistent

Do not depend only on `*.default*` profile names. Prefer parsing each product's `profiles.ini` where available, then fall back to directory discovery.

Generate per profile:

```text
<profile>/chrome/theme-engine.css
```

Maintain a tiny managed `userChrome.css` import instead of replacing the user's existing `userChrome.css`:

```css
@import url("theme-engine.css");
```

Likewise, enable `toolkit.legacyUserProfileCustomizations.stylesheets` without replacing unrelated user.js preferences.

Initial scope should theme browser chrome only:

- tab strip
- selected/inactive tabs
- navigation toolbar
- URL bar
- popup/menu surfaces where selectors are stable
- text/accent/selection/focus colors

Keep pywalfox as an optional enhancement rather than a required dependency.

Browser chrome generally requires restart; `theme` should report `Firefox: restart required` rather than forcibly terminating the browser.

## Phase 2 — Thunderbird

Create a separate Mozilla adapter rather than pretending Firefox CSS is sufficient.

Discover Thunderbird profiles from `~/.thunderbird/profiles.ini` and supported Flatpak locations.

Use the same generated-import pattern:

```text
<profile>/chrome/userChrome.css       # stable import only
<profile>/chrome/theme-engine.css     # generated colors
```

Theme the major surfaces first:

- folder/sidebar tree
- message list
- toolbar/tab strip
- compose/read panes where stable CSS hooks exist

Avoid styling message HTML content by default.

Restart-required behavior should match Firefox.

## Phase 3 — Obsidian

Port the existing Obsidian CSS-variable renderer because it already uses the safest approach: a generated CSS snippet plus `enabledCssSnippets` in `appearance.json`.

Improve discovery so users do not have to hard-code one vault path. Read Obsidian's app metadata/config to discover known vaults where practical, with explicit paths still supported.

For each vault:

```text
<vault>/.obsidian/snippets/theme-engine.css
```

Merge only `theme-engine` into `enabledCssSnippets`; preserve all other appearance settings.

Use Obsidian's CSS variables rather than brittle element selectors wherever possible. This should hot-reload without restarting Obsidian.

## Phase 4 — GTK and Qt application families

Rather than writing one adapter for every GTK/Qt application, theme the toolkit layer.

### GTK

Port the Oomox/GTK adapter behind an explicit prerequisite check. Keep the generated palette separate from hand-maintained GTK configuration. Handle native and Flatpak application theme visibility deliberately.

Targets include apps such as:

- Thunar
- Nautilus
- pavucontrol
- many GTK utilities

### Qt/KDE

Port the existing qt5ct/qt6ct palette generator and KDE color-scheme output.

This covers many apps at once, including:

- Dolphin
- Kate/KWrite
- Okular
- KDE utilities
- Qt applications such as Electrum when they honor the selected palette

Do not overwrite whole qt5ct/qt6ct files. Merge only the selected generated palette path and required custom-palette flag.

## Phase 5 — Editor / terminal family

Port or align the already-proven adapters:

- VSCodium / VS Code: merge only `workbench.colorCustomizations`
- Alacritty: generated imported TOML
- Kitty: already first-class
- Neovim: already first-class

Consider detecting Code variants separately (`Code`, `VSCodium`, `Code - OSS`) because their settings paths differ.

## Phase 6 — Electron applications

Only add app-specific Electron adapters where a supported theming mechanism exists.

Candidates:

- Discord/Vesktop via a supported CSS/theme loader
- Spotify via Spicetify if the user already opted into Spicetify

Do not patch ASAR files or mutate application installation files. If an app has no stable supported/user-configurable theming path, leave it to GTK/Qt/system dark-mode integration or mark it unsupported.

## Semantic palette mapping

All adapters consume the same resolved contract rather than guessing raw theme fields:

```text
surface_0
surface_1
surface_2
overlay
text
text_dim
accent
accent2
selected
hover
focus
border_subtle
border_strong
success
warning
urgent
on_accent
```

Application adapters may derive additional values, but they must derive them from this contract.

## Reload strategy

Adapters report one of:

```text
live          app updates immediately
soft-reload   command/API can refresh safely
restart       user must restart application
session       toolkit change may require relaunch/login
```

At the end of `theme <name>`, display one concise summary, for example:

```text
Applied Tokyo Night
✓ Hyprland       live
✓ Kitty          live
✓ Obsidian       live (2 vaults)
✓ VSCodium       live
✓ GTK            applied
! Firefox        restart required (1 profile)
! Thunderbird    restart required (1 profile)
```

Never kill applications automatically just to apply colors.

## Testing plan

Each adapter gets temporary HOME fixtures with representative configs and assertions that:

- detection finds the correct profiles/vaults
- running twice is idempotent
- unrelated config keys survive unchanged
- existing user CSS is preserved
- first mutation makes exactly one backup
- missing apps are a clean no-op
- malformed JSON/INI fails safely without overwriting the source
- generated colors use resolved semantic roles

Add an integration test that applies two themes consecutively and verifies generated files switch palette without accumulating imports, duplicate snippets, or backup spam.

## Recommended implementation order

1. Extract generic adapter registry + `apps=auto` detection.
2. Port Firefox-family adapter with `profiles.ini` discovery and import-based CSS.
3. Implement Thunderbird using the same Mozilla profile helper.
4. Port/improve Obsidian multi-vault adapter.
5. Port VSCodium and Alacritty adapters.
6. Port Qt/KDE family adapters.
7. Port GTK/Oomox and Flatpak integration.
8. Add status/restart summary UX.
9. Consider optional Electron adapters only after the stable app/toolkit targets are tested.

## Definition of done

Automatic application theming is complete when a fresh Arch-WM install can run:

```bash
theme targets detect
theme <name>
```

and installed supported applications adopt the active palette without the user manually copying CSS, without unrelated settings being overwritten, and with clear reporting for applications that require restart.
