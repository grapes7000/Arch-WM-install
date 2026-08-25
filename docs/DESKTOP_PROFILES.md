# Optional desktop profile manager (`desktopctl`)

`desktopctl` is an **optional** CLI for testing curated Hyprland desktop setups
without handing their upstream installers control of the machine. It is
installed separately:

```bash
./install.sh profile-manager
```

The normal `./install.sh install` path does not install it.

## Safety model

The generic importer never executes a foreign `install.sh`, `setup`, PKGBUILD,
Makefile, QML helper, or repository hook. It clones the repository inertly,
runs deterministic static checks first, optionally asks Codex CLI for a
read-only second opinion, and then copies only paths declared by a local curated
profile.

Deterministic blockers are authoritative. Codex can add warnings but cannot
approve a blocked profile.

Protected personal configuration includes Kitty, Zsh, Starship, Neovim,
Atuin, and the theme engine. Only `hypr`, `quickshell`, and (where explicitly
declared) `waybar` are profile-switched.

A foreign profile also temporarily removes `hypr`, `hyprlock`, and `wallpaper`
from `~/.config/theme-engine/targets.conf`; the exact file is restored when the
captured `arch-wm` recovery profile becomes active again. This prevents the
global theme engine from writing profile-specific compositor files while a
foreign profile is active.

## v0.1 workflow

```bash
desktopctl catalog
desktopctl fetch tsugumori
desktopctl plan tsugumori --codex
desktopctl prepare tsugumori --codex --accept-review
desktopctl packages tsugumori
desktopctl packages tsugumori --apply
desktopctl select tsugumori
```

`select` does not touch live config. It records the pending profile and captures
the current monitor layout when run inside Hyprland.

For the first activation, log out to a TTY and run:

```bash
desktopctl launch --apply
```

`desktopctl` refuses to swap the compositor config when
`HYPRLAND_INSTANCE_SIGNATURE` indicates that Hyprland is currently running.

To go back:

```bash
desktopctl restore
# log out to a TTY
desktopctl launch --apply
```

The first real activation captures the current Arch-WM `hypr`, `quickshell`
and `waybar` trees as a recovery profile and backs up all managed config paths
before replacing them with manager-owned symlinks.

## Codex review

`--codex` is optional. Codex runs only after the deterministic scanner and is
never launched in the foreign repository. It receives generated `profile.json`
and `scan.json` files in a temporary directory, uses a read-only sandbox, has
no install authority, and cannot downgrade a deterministic blocker.

Codex is a semantic second pass, not a security boundary.

## Dependency ownership

Official repository packages installed with `desktopctl packages --apply` are
diffed against the Pacman package set before/after installation and recorded in
`~/.local/state/arch-wm-install/desktop-profiles/packages.json`.

Packages that existed beforehand are marked pre-existing and are never removed
as profile-owned packages. Shared packages retain multiple profile owners.

If a working `qs` executable already exists, v0.1 reuses the current Quickshell
provider rather than requesting a conflicting provider from Pacman. Every
official package install is resolved first using a print-only Pacman
transaction. Profile cleanup uses non-recursive `pacman -R` for manager-owned
packages so dependency trees are not swept opportunistically.

v0.1 intentionally **does not execute AUR PKGBUILDs**. AUR requirements are
reported for review.

## Current curated profiles

- **Tsugumori**: imports `config/hypr`, `config/quickshell`, and
  `config/waybar`; deliberately ignores its Bash and Kitty configs.
- **MainstreamOS**: imports only `dots/.config/hypr` and
  `dots/.config/quickshell`. Its upstream installer, SDDM changes, GPU changes,
  polkit helpers, pacman hooks, boot changes, and gaming-mode system helpers are
  not run.

Mainstream's pinned Quickshell provider is also not replaced in v0.1. The
existing provider is reused so a profile test cannot silently replace the
Quickshell runtime used by another desktop.

## GUI boundary

All read commands support `--json`. The planned Qt frontend should call
`desktopctl` rather than duplicate profile logic:

```text
Qt frontend
    -> desktopctl --json catalog/status/plan
    -> explicit user action
    -> desktopctl prepare/packages/select
```

The CLI remains the source of truth.

## v0.1 limitations

- AUR packages are reported only; they are not installed automatically.
- Runtime compatibility is conservative: an existing Quickshell provider is
  reused rather than replaced.
- Switching is intentionally done outside a running Hyprland session.
- The switch journal and backups are written before config links change, but
  automatic crash recovery from an interrupted switch is a follow-up item.
- This feature must still pass a fresh-Arch VM/live-session smoke test before
  it should be treated as production-safe.
