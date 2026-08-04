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

## Eww policy

Eww is deliberately removed. Do not import:

- Eww configs
- Eww scripts
- Eww tests
- Eww package dependencies
- compatibility wrappers that start Eww

Equivalent functionality belongs in the unified Quickshell widget system.
