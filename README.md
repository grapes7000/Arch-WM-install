# Arch WM Install

A public monorepo for installing and maintaining a custom Arch Linux desktop built around **Hyprland, Quickshell, a portable widget system, and one shared theme contract**.

The project combines the responsibilities of:

- [`grapes7000/themes`](https://github.com/grapes7000/themes)
- [`grapes7000/hyprland-setup`](https://github.com/grapes7000/hyprland-setup)
- a portable Quickshell widget platform
- a staged, reversible installer for a new Arch installation

## Status

The implementation branch currently provides a **first Arch VM smoke-test milestone**, not a production-ready release.

Implemented for this milestone:

- staged Python installer with `minimal`, `desktop`, and `workstation` profiles
- dry-run, resume, stage selection, doctor, tracked backups, rollback, and uninstall
- current Hyprland Lua configuration with machine-local overrides
- atomic universal theme generation for Quickshell, Hyprland, Kitty, and Starship
- a modern Kitty/Zsh terminal profile with an animated Kitty cursor trail
- a manifest-backed portable widget registry
- shared clock, active-window, workspace, and system-stat widgets
- multi-monitor bar and desktop surface hosts driven by JSON layouts
- Hyprlock as the verified authentication boundary for the first milestone
- automated layout, ownership, rollback, theme, syntax, and Eww-exclusion checks

Not yet production-complete:

- media, audio, network, battery, notification, launcher, clipboard, session, and weather widgets
- a secure custom Quickshell lock-screen host
- free-position desktop edit mode
- clean-VM acceptance results across install, reboot, resume, rollback, and uninstall

Read [`AGENTS.md`](AGENTS.md) before extending the implementation.

## Core rule

Widgets do not own windows. A widget is portable content rendered by a surface host. The same widget package can therefore run on:

- the top bar
- the desktop
- the lock screen, when explicitly marked lock-safe

Placement is controlled by JSON layouts rather than separate widget implementations.

## Repository map

```text
Arch-WM-install/
├── install.sh                 # staged installer entrypoint
├── uninstall.sh               # tracked restore/uninstall entrypoint
├── AGENTS.md                  # authoritative implementation contract
├── manifests/                 # package manifests
├── installer/                 # stage framework, profiles, state and rollback
├── modules/
│   ├── shell/                 # Quickshell surfaces, widgets, services and layouts
│   ├── terminal/              # Kitty, Zsh, Atuin and terminal command palette
│   ├── theme-engine/          # universal theme contract and generators
│   └── hyprland/              # current Lua compositor/session configuration
├── vendor/
│   ├── themes/                # optional synced upstream snapshot
│   └── hyprland/              # optional synced upstream snapshot without Eww
├── scripts/                   # sync, validation and VM smoke-test tools
├── docs/                      # design and operating contracts
└── tests/                     # installer, theme and structural tests
```

## First Arch VM smoke test

Use a disposable VM snapshot. The installer tracks and backs up files it replaces, but the first graphical test should not be performed on a daily-driver system.

Clone the implementation branch:

```bash
git clone --branch agent/complete-arch-wm-install --single-branch \
  https://github.com/grapes7000/Arch-WM-install.git
cd Arch-WM-install
```

Run the no-change preflight:

```bash
bash scripts/vm-smoke-test.sh preflight
```

Install into the disposable VM:

```bash
bash scripts/vm-smoke-test.sh install
```

Start or restart Hyprland. From a terminal inside that session, run:

```bash
cd ~/Arch-WM-install
bash scripts/vm-smoke-test.sh post-login
```

Preview tracked rollback:

```bash
bash scripts/vm-smoke-test.sh rollback
```

Perform rollback without removing packages:

```bash
bash uninstall.sh --profile desktop --theme y2k
```

Package removal is deliberately separate:

```bash
bash uninstall.sh --profile desktop --theme y2k --remove-packages
```

## Direct installer commands

Dry-run:

```bash
bash install.sh --profile desktop --theme y2k --dry-run --noninteractive
```

Install:

```bash
bash install.sh --profile desktop --theme y2k --noninteractive
```

Resume an interrupted run:

```bash
bash install.sh --profile desktop --theme y2k --resume --noninteractive
```

Health check:

```bash
PYTHONPATH="$PWD" python -m installer doctor --profile desktop --theme y2k
```

## Upstream import

Maintainers can run:

```bash
bash scripts/sync-upstreams.sh
```

This copies the theme repository into `vendor/themes`, copies the Hyprland repository into `vendor/hyprland`, excludes all Eww paths, and records both source commit SHAs. Runtime installation uses the reviewed modules in this monorepo rather than downloading mutable upstream code.
