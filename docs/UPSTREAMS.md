# Upstream Sources

## Theme engine

- Repository: `grapes7000/themes`
- Destination: `vendor/themes`
- Import policy: complete snapshot, excluding `.git`

## Hyprland setup

- Repository: `grapes7000/hyprland-setup`
- Destination: `vendor/hyprland`
- Import policy: snapshot excluding `.git` and every Eww path

## Why snapshots

A GitHub repository can have only one fork parent. This project needs two upstreams and additional integration code, so it uses locked snapshots instead of claiming a native dual fork.

`scripts/sync-upstreams.sh` records exact source commits in `vendor/UPSTREAM_LOCK.json`. Review diffs before committing a refreshed snapshot.

## Current status

The snapshot pipeline is defined but not currently in use. `vendor/themes` and
`vendor/hyprland` hold only `.gitkeep`, and no `vendor/UPSTREAM_LOCK.json` has
been committed, so nothing is imported from these paths today.

The theme engine is instead fetched at install time: `installer/fixed_entry.py`
shallow-clones `grapes7000/themes` at `main` and runs its `install.sh`. That
means theme installs track upstream `main` rather than a reviewed commit. Run
`scripts/sync-upstreams.sh` and switch the stage over to `vendor/themes` if you
want pinned, reviewable imports.

## Eww policy

Eww is deliberately removed. Do not import:

- Eww configs
- Eww scripts
- Eww tests
- Eww package dependencies
- compatibility wrappers that start Eww

Equivalent functionality belongs in the unified Quickshell widget system.
