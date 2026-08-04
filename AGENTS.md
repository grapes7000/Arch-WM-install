# Agent Implementation Contract

This file is the authoritative brief for agents working on this repository.

## Mission

Turn this scaffold into a reliable, reversible, idempotent installer for a new Arch Linux system. The installed desktop must use Hyprland and a custom Quickshell shell. It must preserve a strict separation between theme data, compositor behavior, shell UI, and machine-specific configuration.

Do not rewrite the project into a single script or a single QML file.

## Non-negotiable architecture

### Theme engine

`vendor/themes` is the imported source from `grapes7000/themes`.

The theme engine owns universal appearance data only:

- semantic colors
- typography tokens
- spacing
- corner radius
- borders
- opacity
- blur intent
- shadow intent
- animation intent
- wallpaper metadata

It must atomically generate this contract:

```text
~/.config/theme-engine/generated/theme.json
```

It must not own keybinds, monitors, window rules, input behavior, autostart, or workspace behavior.

### Hyprland

`vendor/hyprland` is imported from `grapes7000/hyprland-setup`, with all Eww files excluded.

Hyprland owns:

- compositor configuration
- keybinds
- input
- monitors
- window rules
- workspace behavior
- autostart
- translation of universal theme tokens into installed-version-compatible Hyprland syntax

A generated Hyprland appearance file may be produced from `theme.json`, but the conversion code belongs under `modules/hyprland`, not in the theme engine.

### Quickshell

`modules/shell` owns all interactive shell UI:

- bars
- desktop surfaces
- lock-screen surfaces
- launchers
- drawers
- notifications
- OSDs
- session UI
- portable widgets

Do not add Eww as a dependency or retain imported Eww files.

## Portable widget system

Every widget is a package under:

```text
modules/shell/widgets/<widget-id>/
```

A package contains:

```text
manifest.json
Widget.qml
Compact.qml       # optional
Expanded.qml      # optional
Settings.qml      # optional
README.md          # recommended
```

A widget must never instantiate `Window`, `PanelWindow`, `FloatingWindow`, `Lockscreen`, or any screen-anchored object. It must never directly anchor itself to a monitor edge.

A widget receives a `WidgetContext` from its host. The context defines:

- `surface`: `bar`, `desktop`, or `lockscreen`
- `instanceId`
- `variant`
- `density`
- `locked`
- available width and height
- capabilities allowed by the host
- per-instance settings

Widgets must use implicit sizing and adapt to constraints. Shared data comes from shell services, not one watcher process per widget.

### Surfaces

Surface hosts own windows and placement:

- `surfaces/bar`
- `surfaces/desktop`
- `surfaces/lockscreen`

A surface reads a JSON layout, creates widget instances through the registry, passes context, and controls allowed capabilities.

### Layouts

Layouts live under `modules/shell/layouts` and contain widget instances. Example:

```json
{
  "surface": "bar",
  "regions": {
    "start": [{"instance": "workspaces-main", "widget": "workspaces", "variant": "compact"}],
    "center": [{"instance": "clock-main", "widget": "clock", "variant": "compact"}],
    "end": [{"instance": "system-main", "widget": "system-status", "variant": "compact"}]
  }
}
```

Changing a layout must be sufficient to move a compatible widget between bar, desktop, and lockscreen.

### Lock-screen security

The lock surface is a restricted host.

- Widgets must receive `locked: true`.
- Dangerous capabilities are denied by default.
- No arbitrary shell command execution is permitted.
- Media and session actions use explicit allowlists.
- Private notification bodies are hidden unless enabled by policy.
- Desktop and bar hosts must not be visible above the lock surface.

## Installer requirements

The installer must target a network-connected base Arch system and run as a normal user with `sudo` access.

It must:

1. Refuse unsupported distributions unless explicitly overridden.
2. Never run the full installer as root.
3. Support `--dry-run`, `--profile`, `--theme`, `--no-aur`, `--noninteractive`, and `--resume`.
4. Log to `~/.local/state/arch-wm-install/logs`.
5. Store stage state in `~/.local/state/arch-wm-install/state.json`.
6. Back up replaced files beneath `~/.local/share/arch-wm-install/backups/<timestamp>`.
7. Be safe to run repeatedly.
8. Use package manifests rather than embedding giant package arrays in shell code.
9. Bootstrap an AUR helper only after explicit policy allows it.
10. Enable services explicitly and record what it changed.
11. Never replace an entire existing config directory without a backup and ownership manifest.
12. Provide a precise uninstall path that removes only managed files.
13. Validate Hyprland and QML before activating them.
14. Leave a working TTY recovery path if the graphical session fails.

## Installer stages

Keep stages individually runnable and resumable:

```text
00-preflight
10-repositories
20-packages
30-user-dirs
40-theme-engine
50-hyprland
60-quickshell
70-services
80-session
90-validate
```

Each stage implements:

- `check`: determine whether work is needed
- `apply`: make the change
- `verify`: prove the desired state
- `rollback`: undo only that stage's managed changes where practical

## Fresh Arch acceptance test

Use a clean Arch VM snapshot. The final implementation passes only when all of the following are true:

- The base system initially contains no AUR helper, Quickshell config, Hyprland config, or user theme engine.
- One documented command installs the system.
- The user can log into Hyprland through the chosen session launcher.
- The custom shell starts automatically.
- At least one portable widget renders on the bar.
- The same widget can be placed on the desktop by editing layout JSON only.
- A lock-safe widget can render on the lock surface without a second implementation.
- `theme y2k` updates the shell and Hyprland appearance.
- Re-running the installer reports mostly no-op stages.
- Uninstall restores backups and leaves the user with a working TTY.
- No path named `eww`, no Eww package, and no Eww process is required.

## Implementation order

1. Run `scripts/sync-upstreams.sh` and review imported code and licenses.
2. Make validation and tests pass before installing anything.
3. Finish the installer framework and dry-run mode.
4. Normalize the theme JSON contract and add schema validation.
5. Build Hyprland theme translation with version detection.
6. Implement the Quickshell service layer and registry.
7. Implement the three surface hosts.
8. Complete portable widgets one at a time.
9. Implement the lock-screen policy and test it separately.
10. Test a full install in a fresh Arch VM.

## Initial widget set

Implement these as portable packages:

- workspaces
- active-window
- clock-calendar
- media
- volume
- network
- battery
- system-stats
- notifications
- session
- weather as an optional network-backed widget

Each manifest declares compatible surfaces, variants, minimum dimensions, services, capabilities, and lock safety.

## Quality rules

- Prefer Python for generators and structured installation logic; keep shell entrypoints thin.
- Use atomic writes for generated files.
- Use JSON Schema for layouts, widget manifests, profiles, and theme contracts.
- Add tests for idempotency, rollback metadata, schema validation, and absence of Eww.
- Do not copy Caelestia code without license review and source documentation.
- Do not push generated secrets, machine IDs, monitor serials, hostnames, or personal paths.
- Keep machine overrides outside the repository.

## Completion report

At the end, report:

- changed files
- architecture decisions
- tests run
- fresh-VM test result
- remaining warnings
- installation command
- rollback command
