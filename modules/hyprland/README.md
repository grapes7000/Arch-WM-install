# Hyprland Integration

The original non-Eww source is synchronized into `vendor/hyprland`.

This module adapts the universal theme contract to the installed Hyprland version and owns the modular compositor setup.

Keep separate files for:

- environment
- monitors
- input
- behavior
- keybinds
- window rules
- autostart
- generated appearance
- machine-local overrides

The adapter must translate theme roles and style tokens into valid current Hyprland configuration, validate output, then reload only on success.
