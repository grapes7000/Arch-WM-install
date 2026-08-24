# Shared stack migration

Arch-WM-install owns Arch/Hyprland/Quickshell integration. It is not the canonical source of portable shell/editor configuration or theme catalogs.

## Canonical sources

- software/bootstrap: `grapes7000/linux-setup`
- portable user configuration: private `grapes7000/dotfiles`
- theme engine/catalog/generators: `grapes7000/themes`
- Arch/Hyprland/Quickshell integration: this repository

## Installer behavior on this branch

Stage `40-theme-engine` first consumes `~/.local/bin/theme`, which should normally have been installed by `linux-setup` from the standalone themes repository. If it is missing, the built-in theme-engine snapshot is retained as a temporary compatibility fallback so existing installation flows do not fail abruptly.

The theme stage no longer installs or overwrites:

- `~/.zshrc`
- Zsh aliases
- Kitty configuration
- Atuin configuration
- the portable `term` helper

Those are applied by Chezmoi during stage `85-dotfiles`.

## Migration cleanup still intentionally deferred

`modules/terminal` and the built-in `modules/theme-engine` snapshot remain in the repository during this compatibility phase. They may be deleted in a later branch after the external bootstrap path has been exercised on a clean Arch VM and rollback has been verified.

## Rollback

All changes on this branch are isolated from `main`. For an installation performed by this installer, `arch-wm-install uninstall` uses the existing StateStore backups for files this repo owns. Chezmoi and the standalone theme engine remain separate layers and should be rolled back through their own repositories/configuration rather than by restoring Arch-WM's former duplicate terminal files.
