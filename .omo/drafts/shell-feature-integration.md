---
slug: shell-feature-integration
status: planned
intent: clear
review_required: false
pending-action: write .omo/plans/shell-feature-integration.md
approach: Keep the current theme-engine and portable-widget architecture, then add surface-owned QuickShell launcher, exclusive anchored drawers, and a per-monitor auto-hiding task dock. Extend shared services and install Cava; replace the Fuzzel keybind with config-scoped QuickShell IPC.
---

# Draft: shell-feature-integration

## Components (topology ledger)
<!-- Lock the SHAPE before depth. One row per top-level component that can succeed or fail independently. -->
<!-- id | outcome (one line) | status: active|deferred | evidence path -->
| launcher | A keyboard-accessible, searchable native app launcher replaces Fuzzel and persists favorites/recents. | active | `modules/hyprland/config/conf/keybinds.lua`, `modules/shell/shell.qml`, `/home/lakota/Projects/lakota-shell/modules/launcher/Launcher.qml` |
| drawers | One focusable, anchored drawer at a time presents calendar, audio, network, system, notifications, and session detail; backdrop and Escape always dismiss it. | active | `modules/shell/components/MenuPopup.qml`, `modules/shell/surfaces/bar/BarSurface.qml`, `/home/lakota/Projects/lakota-shell/modules/drawers/DrawerWindow.qml` |
| task-dock | Each screen receives a bottom hover-triggered dock of grouped running Hyprland windows with IPC control. | active | `modules/shell/surfaces/desktop/DesktopSurface.qml`, `/home/lakota/Projects/lakota-shell/modules/dock/TaskDock.qml` |
| shared-data | Audio, network, system, notification, MPRIS, Tailscale, and Cava state are exposed by shared services, never per-widget watchers. | active | `modules/shell/services/*.qml`, `/home/lakota/Projects/setup/hyprland-setup/eww/waybar-panels/eww.yuck` |
| delivery-and-qa | Installer deploys all managed assets and Cava; automated and live-session checks prove single-shell operation and core interaction. | active | `manifests/packages-shell.txt`, `scripts/vm-smoke-test.sh`, `tests/test_structure.py` |

## Open assumptions (announced defaults)
<!-- Record any default you adopt instead of asking, so the user can veto it at the gate. -->
<!-- assumption | adopted default | rationale | reversible? -->
| Appearance | Retain the current theme-engine visual language; reimplement Lakota behaviors without copying its QML or assets. | `lakota-shell` has no repository license file, while this repo requires theme-engine ownership of universal appearance. | yes |
| Cava | Install `cava` in the shell manifest and include its audio spectrum in the default audio drawer. | User selected default installation. | yes |
| Tests | Tests-after: add focused tests with each subsystem, then run QML lint, layout validation, Python tests, and a live Hyprland/Quickshell smoke pass. | User selected it; the repo already has focused Python structural tests. | yes |
| Drawer scope | Do not create an application-overview drawer; the launcher and grouped task dock replace the old Waybar/Eww apps panel. | Avoids two overlapping ways to select applications. | yes |
| Desktop shelf | Ship an empty default desktop layout and remove the persistent top-right shelf; its current clock/system detail moves to temporary drawers and the dock is the only default desktop surface. | User selected the clear-desktop default after the live diagnosis confirmed this shelf is the apparent second bar. | yes |
| Widget boundary | Keep widgets limited to `bar`, `desktop`, and `lockscreen`; launcher, drawers, and dock are host-owned shell UI. | Preserves the portable-widget contract and lock-surface policy. | no |

## Findings (cited - path:lines)

- `modules/shell/shell.qml:1-10` instantiates only bar and desktop hosts; no native launcher, task dock, or IPC handler exists.
- `modules/hyprland/config/conf/env.lua:1-3` assigns `archwm.menu = "fuzzel"`, and `modules/hyprland/config/conf/keybinds.lua:6-8` invokes it for `SUPER + Space`.
- `modules/shell/components/MenuPopup.qml:7-75` is a single full-screen dismissible control-center overlay; `modules/shell/surfaces/bar/BarSurface.qml:11-154` exposes just one unlabeled menu trigger.
- `modules/shell/components/WidgetHost.qml:99-109` and `modules/shell/core/SurfaceRegistry.qml:8-31` enforce the portable-widget context/capability boundary that new interactive shell surfaces must preserve.
- `modules/shell/services/AudioService.qml:7-65` exposes only output volume/mute, and `modules/shell/services/NetworkService.qml:7-74` exposes only current connection/rates; the richer upstream panel behavior must be shared-service work.
- `/home/lakota/Projects/lakota-shell/modules/launcher/Launcher.qml`, `/home/lakota/Projects/lakota-shell/modules/dock/TaskDock.qml`, and `/home/lakota/Projects/lakota-shell/modules/drawers/DrawerWindow.qml` demonstrate the target QuickShell capabilities, including `DesktopEntries`, Hyprland toplevels, popup anchoring, and IPC.
- `/home/lakota/Projects/setup/hyprland-setup/eww/waybar-panels/eww.yuck:76-226` is the source of the desired rich audio/network/system/calendar detail but is Eww-only; this repository expressly forbids importing Eww.
- `manifests/packages-shell.txt:1-6` lacks Cava, and `qs --version` reports QuickShell `0.3.0` with config-scoped IPC available under `qs -c arch-wm ipc call`.
- `/home/lakota/Projects/lakota-shell/docs/SOURCES.md:1-6` asserts original code but the repository has no `LICENSE*`, so the implementation must not copy source or assets.

## Decisions (with rationale)

- Integrate the best behavior of all three sources into the existing architecture, rather than merging either external shell: this repo provides installer/theme/portable-widget safety; Lakota Shell provides native launcher/dock/drawer interaction; hyprland-setup provides detailed status surfaces.
- Use config-scoped QuickShell IPC as the launcher and dock control plane, replacing Fuzzel at `SUPER + Space` and adding documented dock controls.
- Use one drawer coordinator with a full-screen backdrop and Escape dismissal. It must close the previous drawer before opening another and target the emitting bar screen, eliminating stacked, uncloseable overlays.
- Make the dock a desktop-host-owned `Variants` surface using native Hyprland toplevel data; no widget opens its own window or pins itself to a monitor edge.
- Empty `layouts/desktop.default.json` for the default profile so `DesktopSurface` does not create the persistent top-right 340px shelf; retain the existing layout schema so a user may opt back in through layout JSON only.
- Add Cava as an explicit managed package and treat an unavailable/failed Cava process as a non-fatal, hidden visualizer while audio controls continue to work.
- Keep lock-screen policy unchanged: launcher, drawers, and dock are absent above the lock; only the existing lock-safe widgets and granted capabilities remain available.

## Scope IN

- Native launcher with search, categories, favorites/recents stored in XDG state, keyboard navigation, `DesktopEntries`, IPC, and the `SUPER + Space` binding.
- Exclusive calendar, audio, network, system, notifications, and session drawers built from current theme tokens and shared services; audio includes MPRIS, sink/source controls, per-app volume, Cava; network includes Wi-Fi scan/connect and VPN/Tailscale status; system includes temperature/top processes; notifications include history/clear/DND.
- Per-screen auto-hiding bottom task dock grouped by application, with focus behavior and a multi-window chooser; an empty default desktop shelf to clear the existing persistent top-right panel.
- Service, installer, versioning, documentation, automated tests, lint, layout validation, and a live-session smoke scenario for the above.

## Scope OUT (Must NOT have)

- No Eww, Waybar, Caelestia, Fuzzel launcher, or copied Lakota Shell QML/assets in the managed shell.
- No new portable-widget surface kind, widget-created windows, duplicated service polling, or unbounded shell-command execution on the lock surface.
- No theme-engine ownership of keybinds, window behavior, monitor placement, or machine-specific state.
- No imported `hyprland-setup` files beyond behavioral/data-contract reference; preserve its dirty worktree untouched.

## Open questions

None. The user chose full interactive scope, a default Cava installation, current theme-engine styling, and tests-after.

## Approval gate
status: approved
<!-- When exploration is exhausted and unknowns are answered, set status: awaiting-approval. -->
<!-- That durable record is the loop guard: on a later turn read it and resume at the gate instead of re-running exploration. -->
Approved plan written at `.omo/plans/shell-feature-integration.md`. The Metis gap review was integrated: Hyprlock remains sole lock UI; VM portability uses a temporary layout; every managed Fuzzel reference is removed; dock membership, IPC, service, secret/session, and evidence policies are explicit. Execution requires a separate worker session.
