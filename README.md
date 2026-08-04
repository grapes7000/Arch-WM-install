# Arch WM Install

A public monorepo scaffold for installing and maintaining a custom Arch Linux desktop built around **Hyprland, Quickshell, and one shared theme contract**.

The project combines the responsibilities of:

- [`grapes7000/themes`](https://github.com/grapes7000/themes)
- [`grapes7000/hyprland-setup`](https://github.com/grapes7000/hyprland-setup)
- a new portable Quickshell widget platform
- an idempotent installer for a brand-new Arch installation

## Status

This repository is deliberately scaffold-first. It contains the architecture, contracts, portable widget example, upstream-sync tooling, validation, and a detailed implementation brief for a coding agent. It is **not yet a production installer**.

Read [`AGENTS.md`](AGENTS.md) before implementing anything.

## Core rule

Widgets do not own windows. A widget is portable content rendered by a surface host. The same widget package can therefore run on:

- the top bar
- the desktop
- the lock screen

Placement is controlled by JSON layouts rather than separate widget implementations.

## Repository map

```text
Arch-WM-install/
├── install.sh                 # staged installer entrypoint
├── uninstall.sh               # reversible uninstall entrypoint
├── AGENTS.md                  # authoritative agent implementation brief
├── config/                    # installer defaults and profiles
├── manifests/                 # package and service manifests
├── installer/                 # stage framework and shared installer libraries
├── modules/
│   ├── shell/                 # Quickshell surfaces, widgets, services and layouts
│   ├── theme-engine/          # wrapper around the imported themes repository
│   └── hyprland/              # wrapper around the imported Hyprland repository
├── vendor/
│   ├── themes/                # synced snapshot of grapes7000/themes
│   └── hyprland/              # synced snapshot without Eww content
├── scripts/                   # sync and validation tools
├── docs/                      # design and operating contracts
└── tests/                     # structural and installer tests
```

## Upstream import

Run:

```bash
./scripts/sync-upstreams.sh
```

This copies the theme repository into `vendor/themes`, copies the Hyprland repository into `vendor/hyprland`, excludes all Eww paths, and records both source commit SHAs.

## Intended final installation

```bash
./install.sh --profile desktop --theme y2k
```

The finished installer must work from a network-connected, base Arch installation under a normal user with `sudo` access. See [`docs/INSTALLER.md`](docs/INSTALLER.md).
