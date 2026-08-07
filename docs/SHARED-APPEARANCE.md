# Shared appearance contract

The shell, theme engine, and Hyprland share one appearance contract at:

```text
~/.config/theme-engine/generated/theme.json
```

The theme engine owns the universal appearance data and validates it with
`modules/theme-engine/schema/theme.schema.json`. Quickshell reads the same
contract directly through `Core.Theme`. Hyprland consumes the same contract
through `~/.config/hypr/scripts/theme-sync.py`, which translates portable
appearance intent into live `hyprctl` settings.

This does **not** move compositor behavior into the theme engine. Keybinds,
monitors, input policy, window rules, autostart, and workspace behavior remain
under `modules/hyprland`.

## Shared style tokens

Along with existing color, radius, gap, opacity, blur, shadow, border, and
animation-duration tokens, the contract supports:

- `surface_opacity`: shell card/surface opacity from 0 to 1.
- `animation_profile`: `minimal`, `smooth`, `snappy`, or `dramatic`.
- `workspace_animation`: `slide`, `slidevert`, or `fade`.
- `motion_scale`: global motion multiplier from 0 to 2; `0` disables Hyprland
  animations and makes shell transitions effectively immediate.

Themes do not have to specify the newer tokens. Quickshell and Hyprland use
stable defaults, and Hyprland derives a compatible animation profile from the
legacy `animation_ms` token when `animation_profile` is absent.

## Hyprland behavior additions

The compositor configuration provides three named special workspaces:

- `scratch`: `Super+Z`; move the focused window with `Super+Shift+Z`.
- `music`: `Super+N`; move the focused window with `Super+Shift+N`.
- `comms`: `Super+C`; move the focused window with `Super+Shift+C`.

Smart window rules float common settings tools, file pickers, authentication
prompts, calculators, and picture-in-picture windows while leaving normal app
windows tiled.

## Live updates

`theme-sync.py` watches `generated/theme.json`. Changing themes therefore
updates shared Hyprland appearance and animation intent without requiring the
shell and compositor to maintain separate theme settings files.
