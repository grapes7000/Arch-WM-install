# Installer Contract

## Supported starting point

A fresh, network-connected Arch Linux base installation with:

- a non-root user
- working `sudo`
- mounted and persistent root filesystem
- system clock synchronized
- internet access

Disk partitioning, encryption and the base Arch installation are intentionally out of scope for the first stable release. They may become a separate guided stage later.

## User-facing command

```bash
./install.sh --profile desktop --theme y2k
```

Useful modes:

```bash
./install.sh --dry-run
./install.sh --resume
./install.sh --no-aur
./install.sh --noninteractive
./install.sh help
./uninstall.sh --restore latest
```

## On-system reference

`help` (alias for `arch-wm-help`) prints the desktop quick reference: every
keybind plus the important file locations (Hyprland config, shell sources,
homepage background images, generated theme contract, logs, backups and
more). The reference is regenerated from the installed keybinds on every
installer run, so it never drifts from what is actually configured.

```bash
help                  # in the installed shell
arch-wm-help          # same reference, any shell
./install.sh help     # same reference, from a development checkout
```

## State model

The installer must record:

- repository revision
- selected options
- completed stage versions
- packages installed by this project
- services enabled by this project
- every managed path
- every backup path
- generated file hashes

State lives beneath:

```text
~/.local/state/arch-wm-install/
```

Backups live beneath:

```text
~/.local/share/arch-wm-install/backups/<timestamp>/
```

## Idempotency

Every stage performs detection before mutation. A second run must not duplicate config lines, reinstall unchanged links, recreate users, or repeatedly overwrite backups.

Use atomic replacement for generated JSON and config. Validate temporary output before renaming it into place.

## Ownership markers

Generated files must include a header identifying Arch WM Install. For formats that do not support comments, track ownership and checksums in state.

Never remove a path during uninstall unless state proves this project created or replaced it.

## Package policy

- Official packages use `pacman`.
- AUR packages use one selected helper.
- The AUR helper bootstrap must be isolated, reviewed and disabled by `--no-aur`.
- Package names are stored in manifests.
- The implementation must verify current package names before release.

## Activation safety

Before enabling the graphical session:

1. validate generated JSON
2. validate Python and shell syntax
3. run QML tooling or a controlled Quickshell test launch
4. validate Hyprland configuration using the installed version's supported method
5. keep the previous config and a TTY recovery command

## Profiles

A profile controls optional components, not theme identity. Initial profiles:

- `minimal`: Hyprland, terminal, portals and essential shell
- `desktop`: full shell and standard utilities
- `workstation`: development and creative tools layered on desktop

Machine-specific monitor configuration must be generated or stored locally, never assumed by the profile.
