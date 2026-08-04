# Architecture

## Layers

```text
Theme definitions
      │
      ▼
~/.config/theme-engine/generated/theme.json
      ├──────────────► Hyprland theme adapter ─► generated Hyprland appearance
      └──────────────► Quickshell Theme service ─► every surface and widget

System APIs
  Hyprland / MPRIS / PipeWire / NetworkManager / UPower / notifications
      │
      ▼
Quickshell shared services
      │
      ▼
Portable widgets
      │
      ▼
Surface hosts: bar / desktop / lockscreen
      │
      ▼
Layout JSON selects placement, instance settings and variants
```

## Directory responsibilities

### `vendor/`

Read-only snapshots of the two original repositories. Update them through `scripts/sync-upstreams.sh`; do not casually edit snapshots in place.

### `modules/theme-engine/`

Integration code around the imported theme engine: JSON schema, atomic publishing, migration, target adapters and tests.

### `modules/hyprland/`

Hyprland-specific configuration and theme translation. Machine-specific monitors belong in an ignored local override, not source control.

### `modules/shell/`

The Quickshell product. Widgets are portable content; surfaces are the only layer allowed to create windows.

### `installer/`

Idempotent orchestration. It owns installation state and managed-file metadata but not application business logic.

## Configuration precedence

From lowest to highest priority:

1. repository defaults
2. selected profile
3. selected theme
4. user config under `~/.config/arch-wm-install`
5. machine-local overrides
6. command-line arguments

Generated files must state their source and must never be edited by hand.

## Repository import model

GitHub supports one fork parent, not two. This monorepo therefore uses reproducible vendored snapshots with commit locking. The original repositories remain independent upstreams, while this repository is the installable integration point.
