# Theme Engine Integration

The original source is synchronized into `vendor/themes`.

Build integration here rather than coupling consumers directly to upstream internals. This module must provide:

- a versioned JSON Schema for the universal theme contract
- atomic generation of `~/.config/theme-engine/generated/theme.json`
- migration from existing theme definitions
- stable CLI behavior such as `theme <name>`
- tests for semantic roles and fallbacks
- consumer notification after a successful atomic update

Hyprland syntax generation does not belong here. It belongs in `modules/hyprland`.
