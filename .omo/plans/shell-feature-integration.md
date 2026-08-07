# shell-feature-integration - Work Plan

## TL;DR (For humans)

**What you'll get:** A cohesive, theme-aware Quickshell desktop with a keyboard launcher, exclusive detail drawers, rich system controls, and an auto-hiding task dock on every monitor. The default desktop is clear, so the former top-right shelf no longer resembles a second bar.

**Why this approach:** The current repository remains the owner of installation, theming, and portable widgets; only proven interaction patterns are reimplemented. This preserves the existing security and layout boundaries while completing the shell.

**What it will NOT do:** It will not install or use Eww, Waybar, Fuzzel, or copied third-party QML/assets. Hyprlock remains the authentication screen; this work does not enable a custom Quickshell lock UI.

**Effort:** Large
**Risk:** Medium - QuickShell 0.3 input/layer behavior and PipeWire/NetworkManager integration require a live Hyprland VM check.
**Decisions to sanity-check:** Cava and Dunst are default packages; docks show grouped windows on their assigned monitor across workspaces; launcher state remains user data after uninstall.

Your next move: run this plan in a separate worker session with `$start-work shell-feature-integration`. Full execution detail follows below.

---

> TL;DR (machine): Large, medium-risk Quickshell integration delivering IPC launcher, exclusive themed drawers, rich shared services, per-monitor task dock, clear default desktop layout, and VM-backed verification.

## Scope

### Must have

- Reimplement selected Lakota Shell launcher, drawer, dock, state persistence, and IPC behaviors with current theme-engine tokens and architecture.
- Reimplement useful hyprland-setup status data: calendar, Cava audio spectrum, PipeWire source/stream controls, Wi-Fi connect, VPN/Tailscale status, temperature/top processes, and Dunst history.
- Remove every managed Fuzzel reference; install Cava and Dunst; deploy all additions through the versioned installer payload.
- Keep `bar`, `desktop`, and `lockscreen` as the only portable widget surface kinds. Launcher, drawers, and dock remain host-owned windows.
- Ship an empty default desktop layout while retaining JSON-only widget portability for opt-in desktop placement.

### Interfaces

- Add `WidgetContext.request(capability, payload)`. It returns `false` unless `allows(capability)` is true. Bar widgets may request `drawer.open` with `{ kind, anchorItem }`; desktop and lockscreen hosts always reject it.
- The bar drawer coordinator provides `open(kind, anchorItem, screen)`, `close()`, and one `activeKind`; changing kind closes the previous drawer first.
- Fix IPC commands to `qs -c arch-wm ipc call launcher open|close|toggle`, `qs -c arch-wm ipc call dock open|close|toggle`, and `qs -c arch-wm ipc call drawers open <kind> [screenName]|close`. Valid kinds: `calendar`, `audio`, `network`, `system`, `notifications`, `session`, `weather`. Invalid, locked, or absent-instance calls open nothing and return nonzero.
- Launcher state is `~/.local/state/arch-wm-shell/launcher.json`: `{"schemaVersion":1,"favorites":[desktopEntryId],"recents":[desktopEntryId]}`. Favorites keep user order; each launch moves a unique ID to the front of recents, capped at 10. Invalid state loads empty and is atomically replaced only on the next user mutation. It is not removed by uninstall.
- Shared QML service contracts expose: audio sink/source/stream rows and actions; network active connection, Wi-Fi scan rows, guarded connect state; system CPU/memory/disk/uptime/temperature/top five processes; Dunst paused/count/recent five rows; Cava `available`, `running`, and at most 24 normalized bars.

### Must NOT have (guardrails, anti-slop, scope boundaries)

- Do not copy Lakota Shell source/assets or import Eww, Waybar, Caelestia, or hyprland-setup configuration.
- Do not add a `drawer` widget surface, let widgets create a window, or add a watcher/process per widget.
- Do not enable `LockSurface.qml`. Hyprlock remains the sole authentication boundary. `LockedHint=true` closes/hides bar, desktop, launcher, drawers, and dock, and denies their IPC.
- Do not persist/log Wi-Fi passwords, connect/disconnect VPNs, expose notification bodies while locked, or execute logout/suspend/reboot/poweroff without a second explicit confirmation.

## Verification strategy

> Zero human intervention - all verification is agent-executed.

- Test decision: tests-after using Python `unittest`, JSON/layout validation, shell syntax checks, `qmllint`, and a disposable Hyprland/Quickshell VM session.
- Baseline commands: `python scripts/validate-layouts.py`; `python -m unittest discover -s tests -v`; `bash -n scripts/vm-smoke-test.sh`; and `find modules/shell -name '*.qml' -print0 | xargs -0 qmllint` for the changed QML.
- Evidence goes under `.omo/evidence/shell-feature-integration/` as task-specific command logs, `hyprctl layers -j` JSON, and screenshots.
- The VM flow must prove: one daemon, no Fuzzel, empty default desktop shelf, launcher open/close, drawer replacement/dismissal, dock reveal, Cava failure fallback, temporary JSON-only desktop widget placement, and shell hiding after `loginctl lock-session`.

## Execution strategy

### Parallel execution waves

- Wave 1: control/lock foundation, shared services, launcher, and dock.
- Wave 2: drawer/widget interaction, delivery/defaults, automated validation, and VM smoke.

### Dependency matrix

| Todo | Depends on | Blocks | Can parallelize with |
| --- | --- | --- | --- |
| 1 | none | 3, 4, 5, 7, 8 | 2 |
| 2 | none | 5, 6, 7, 8 | 1, 3, 4 |
| 3 | 1 | 6, 7, 8 | 2, 4 |
| 4 | 1 | 6, 7, 8 | 2, 3 |
| 5 | 1, 2 | 6, 7, 8 | none |
| 6 | 2, 3, 4, 5 | 7, 8 | none |
| 7 | 1-6 | 8 | none |
| 8 | 1-7 | F1-F4 | none |

## Todos

- [x] 1. Establish the interactive-shell control plane and lock guard
  What to do / Must NOT do: Add `LockStateService.qml` (poll `loginctl show-session "$XDG_SESSION_ID" -p LockedHint --value`) and a Hyprland screen resolver. Extend `WidgetContext.qml`, `WidgetHost.qml`, and `SurfaceRegistry.qml` with the capability-checked request callback; bar supplies it and desktop/lockscreen reject it. Add the exact `launcher`, `drawers`, and `dock` IPC targets. Bind interactive surfaces to unlocked state and close them on lock. Do not instantiate `LockSurface.qml` or loosen lock-safe capabilities.
  Parallelization: Wave 1 | Blocked by: none | Blocks: 3, 4, 5, 7, 8
  References: `modules/shell/shell.qml:1-10`; `modules/shell/core/WidgetContext.qml:3-16`; `modules/shell/components/WidgetHost.qml:99-109`; `modules/shell/core/SurfaceRegistry.qml:8-31`; `modules/shell/surfaces/lockscreen/LockSurface.qml:1-8`; `modules/shell/{,services/}qmldir`; `qs ipc call --help`.
  Acceptance criteria: `qs -c arch-wm ipc show` lists exactly `launcher`, `drawers`, and `dock`; invalid/locked calls create no interactive layer in `hyprctl layers -j`; lock transition removes all Arch WM interactive namespaces.
  QA scenarios: happy: invoke launcher IPC then inspect `hyprctl layers -j`; failure: invoke `drawers open invalid` and launch IPC after `loginctl lock-session`, asserting no new layer. Evidence `task-1-control-plane.{txt,json}`.
  Commit: Y | `feat(shell): add interactive control and lock guard`

- [x] 2. Expand shared system services and managed dependencies
  What to do / Must NOT do: Refactor `AudioService`, `NetworkService`, `SystemStatsService`, `NotificationService`, `MprisService`, and `SessionService`; add `CavaService` and qml exports. Use one bounded `Process` per service with typed state and stale-data clearing. Audio uses PipeWire/WirePlumber `wpctl` for sink/source/streams; NetworkManager `nmcli` supplies link/scan state; Wi-Fi passwords exist only in a focused drawer field, clear on exit/15-second timeout, and need explicit Connect; system sampling caps processes at five; Dunst supplies history/DND; Cava outputs at most 24 bars and hides on failure. Tailscale/Mullvad are display-only. Lock is immediate; logout/suspend/reboot/poweroff require a second click within four seconds and report process failures.
  Parallelization: Wave 1 | Blocked by: none | Blocks: 5, 6, 7, 8
  References: `modules/shell/services/{Audio,Network,SystemStats,Notification,Mpris,Session,Tailscale,Power}Service.qml`; `manifests/packages-hyprland.txt:20-25`; `/home/lakota/Projects/setup/hyprland-setup/eww/waybar-panels/eww.yuck:76-192`; `/home/lakota/Projects/lakota-shell/scripts/shell-data:104-124` for behavior/data shape only.
  Acceptance criteria: all documented fields/actions exist; malformed or unavailable command output results in empty/error state, never stale data; `dunst` and `cava` occur once in the shell manifest; no service command passes a password through `sh -c` or logs it.
  QA scenarios: happy: sample `wpctl`, `nmcli`, `dunstctl history`, `tailscale status --json`, and Cava in VM then capture drawer values; failure: stop Dunst/kill Cava and use invalid NetworkManager fixture, confirming working non-visualizer controls. Evidence `task-2-services.{txt,json,png}`.
  Commit: Y | `feat(shell): add rich shared status services`

- [x] 3. Implement the native searchable launcher and retained state
  What to do / Must NOT do: Add a bar-host-owned full-screen launcher overlay using `DesktopEntries`, Todo 1 active-monitor selection, category/search ranking, favorites/recents, arrow navigation, Enter launch, Escape/backdrop close, and the fixed IPC contract. Add `LauncherStateService` with the Scope schema, atomic writes, parent-directory creation, and pruning of unknown desktop IDs. Do not add Fuzzel fallback, copy Lakota QML, or let a widget own this window.
  Parallelization: Wave 1 | Blocked by: 1 | Blocks: 6, 7, 8
  References: `modules/hyprland/config/conf/{keybinds,env}.lua`; `modules/shell/surfaces/bar/BarSurface.qml:8-162`; `/home/lakota/Projects/lakota-shell/modules/launcher/Launcher.qml:8-101,284-289`; `/home/lakota/Projects/lakota-shell/services/LauncherState.qml:7-70` as behavior-only references.
  Acceptance criteria: `qs -c arch-wm ipc call launcher open|close|toggle` behaves deterministically on the active monitor; launching an entry produces schema-valid unique/capped state; corrupt state loads empty without QML errors.
  QA scenarios: happy: seed two VM fixture `.desktop` files, launch one through keyboard input, inspect state JSON; failure: corrupt `launcher.json`, reload Quickshell, and reopen launcher. Evidence `task-3-launcher.{txt,json,png}`.
  Commit: Y | `feat(shell): add native application launcher`

- [x] 4. Implement the monitor-filtered auto-hiding task dock
  What to do / Must NOT do: Add a desktop-host-owned `Variants` dock window independent of `DesktopSurface` shelf visibility. Use `Quickshell.Hyprland` to include only mapped toplevels assigned to that dock monitor, across its workspaces. Group by normalized desktop-entry `startupClass`, then entry ID, then app class/appId, with address fallback. One-window groups activate; multi-window groups open a title/workspace chooser. Hover reveal/hide and dock IPC act only on the active monitor. Use a masked bottom-center hit zone so a hidden dock does not block desktop input.
  Parallelization: Wave 1 | Blocked by: 1 | Blocks: 6, 7, 8
  References: `modules/shell/surfaces/desktop/DesktopSurface.qml:8-66`; `/home/lakota/Projects/lakota-shell/modules/dock/DockWindow.qml:9-121,231-313`; `/home/lakota/Projects/lakota-shell/modules/dock/TaskDock.qml`; `modules/shell/core/Theme.qml`.
  Acceptance criteria: each detected screen has one dock namespace even with empty desktop layout; two same-class windows on one monitor are one group, a different class is another, and a remote-monitor window is excluded.
  QA scenarios: happy: start two Kitty windows and one second-class window across two monitors, open dock IPC, capture layers/screenshot, focus through chooser; failure: zero toplevels or invalid mapping yields an empty non-blocking dock without QML error. Evidence `task-4-dock.{txt,json,png}`.
  Commit: Y | `feat(shell): add multi-monitor task dock`

- [ ] 5. Add exclusive themed drawers alongside the existing control center
  What to do / Must NOT do: Preserve the existing `MenuPopup` control center and its trigger. Add a bar-surface drawer controller and theme-driven calendar, audio, network, system, notifications, session, and weather drawer content without deleting or replacing the control center. Each drawer is focusable, anchors to the emitting widget on its bar screen, closes via backdrop/Escape, and replaces any prior drawer. Map requests: clock→calendar; media/volume→audio; network→network; system-stats→system; notifications→notifications; session→session; weather→weather. Update manifests and `generated/widgets.json` with `drawer.open`; preserve noninteractive widget behavior when a host rejects a request. Ensure opening the control center does not leave a drawer open.
  Parallelization: Wave 2 | Blocked by: 1, 2 | Blocks: 6, 7, 8
  References: `modules/shell/components/MenuPopup.qml:7-75`; `modules/shell/surfaces/bar/BarSurface.qml:11-156`; `modules/shell/widgets/*/{Widget.qml,manifest.json}`; `modules/shell/generated/widgets.json`; `scripts/validate-layouts.py:44-143`; `/home/lakota/Projects/lakota-shell/modules/drawers/DrawerWindow.qml:1-53` as behavior-only reference.
  Acceptance criteria: opening a drawer after another yields exactly one Arch WM drawer layer; backdrop/Escape close it; anchor screen matches the triggering bar; lock closes it; controls invoke only declared service actions.
  QA scenarios: happy: `drawers open audio`, then `drawers open network`, then `drawers close`, asserting layer count 1→1→0; failure: rejected desktop/lockscreen request and invalid drawer IPC create no window. Evidence `task-5-drawers.{txt,json,png}`.
  Commit: Y | `feat(shell): replace control center with drawers`

- [ ] 6. Wire compositor, installer, defaults, and documentation
  What to do / Must NOT do: Replace `SUPER + Space` with config-scoped QuickShell launcher IPC. Remove Fuzzel from both Hyprland config variants and `packages-hyprland.txt`; add Cava/Dunst to `packages-shell.txt`; start Dunst once without duplicates. Preserve no-duplicate behavior in emergency shell launch. Empty `layouts/desktop.default.json` while keeping its schema. Bump shell/Hyprland payload versions and extend installer verification for launcher/drawer/dock assets. Document architecture, IPC/keybinds, retained user state, packages, no-Eww guarantee, and opt-in desktop layout editing.
  Parallelization: Wave 2 | Blocked by: 2, 3, 4, 5 | Blocks: 7, 8
  References: `modules/hyprland/config/conf/{keybinds.lua,env.lua,env.conf,autostart.lua}`; `manifests/packages-{hyprland,shell}.txt`; `modules/shell/layouts/desktop.default.json`; `modules/{shell,hyprland}/.arch-wm-version`; `installer/entry.py:169-222`; `scripts/force-shell-repair.sh:38-42`; `docs/ARCHITECTURE.md:1-66`.
  Acceptance criteria: fresh deploy installs bumped version markers and new assets; manifests contain Cava/Dunst but never Fuzzel; no `SUPER + Space` Fuzzel route; default desktop layout validates and has zero instances.
  QA scenarios: happy: run installer `--dry-run`, then disposable VM install and inspect installed payload/version; failure: preseed matching old marker and assert version bump forces shell/Hyprland deployment. Evidence `task-6-delivery.{txt,json}`.
  Commit: Y | `feat(installer): deploy integrated interactive shell`

- [ ] 7. Replace obsolete assertions with behavioral and contract coverage
  What to do / Must NOT do: Replace old fixed-version/MenuPopup text assertions with focused tests for manifest/registry synchronization, capability grants/rejections, forbidden managed Fuzzel/Eww, package uniqueness, empty default desktop JSON, launcher-state normalization, installer version deployment, and smoke command construction. Add QML lint where a QuickShell runner is available; do not make source-string matching the only interaction proof.
  Parallelization: Wave 2 | Blocked by: 1-6 | Blocks: 8
  References: `tests/test_structure.py:21-116`; `tests/test_installer_core.py:19-228`; `scripts/validate-layouts.py:1-179`; `.github/workflows/validate.yml:1-39`; `scripts/vm-smoke-test.sh:66-105`; Scope interfaces.
  Acceptance criteria: baseline validation commands pass; temporary fixtures with Fuzzel, unsupported capability, malformed state, nonempty default shelf, or mismatched registry fail their focused test.
  QA scenarios: happy: run complete focused validation; failure: exercise each temporary invalid fixture. Evidence `task-7-tests.txt`.
  Commit: Y | `test(shell): cover interactive shell contracts`

- [ ] 8. Expand the disposable-VM interaction smoke test and record evidence
  What to do / Must NOT do: Replace old portable-widget assertions with an empty-default-layout check, then temporarily copy a clock desktop layout, wait for reload, assert its layer, and restore the empty layout. Add noninteractive IPC/layer/screenshot checks for launcher, exclusive drawers, dock, Cava fallback, one-daemon guard, and lock hiding. Stop after the lock check because the disposable session remains locked. Keep the test away from normal user configuration and do not claim unavailable mouse automation.
  Parallelization: Wave 2 | Blocked by: 1-7 | Blocks: F1-F4
  References: `scripts/vm-smoke-test.sh:58-105`; `modules/shell/layouts/{bar,desktop}.default.json`; `modules/shell/surfaces/desktop/DesktopSurface.qml:27-33`; `modules/hyprland/config/conf/autostart.lua:1-16`; `.omo/evidence/interaction-repair/layers-final-closed.json`.
  Acceptance criteria: VM produces all named evidence; each open surface has one named layer, each close/lock removes it, and restored default desktop remains empty/valid.
  QA scenarios: happy: run VM smoke then IPC and `hyprctl layers -j`; failure: duplicate `qs`, failed Cava, absent Dunst, invalid IPC, and locked session produce clear errors without extra surfaces. Evidence `task-8-vm-smoke.{txt,json,png}`.
  Commit: Y | `test(vm): exercise integrated shell surfaces`

## Final verification wave

- [ ] F1. Plan compliance audit
  Verify every diff maps to Todos 1-8, preserves no-Eww/no-copy/no-custom-lock guards, and records installer ownership/version updates. Evidence `f1-plan-compliance.md`.
- [ ] F2. Code quality review
  Review QML process lifecycles, secret clearing, IPC validation, monitor filtering, and user-state/uninstall behavior; reject text-only interaction proof. Evidence `f2-code-review.md`.
- [ ] F3. Real manual QA
  Execute the disposable-VM smoke flow with captured layers/screenshots and inspect launcher, drawers, dock, fallback, and lock-hide outcomes. Evidence `f3-live-qa.md`.
- [ ] F4. Scope fidelity
  Confirm theme-engine styling, no third-party source/assets, clear default desktop, and complete requested behavior without custom lock host. Evidence `f4-scope-fidelity.md`.

## Commit strategy

- Commit 1: control plane and shared services.
- Commit 2: launcher, dock, and drawers.
- Commit 3: installer/Hyprland/default-layout/docs integration.
- Commit 4: automated and VM smoke validation.
- Preserve unrelated worktree changes, including existing interaction-repair edits, unless directly superseded by drawer replacement.

## Success criteria

- Fresh Arch VM logs into one `arch-wm` QuickShell instance with no Fuzzel, Eww, Waybar, or persistent top-right shelf.
- `SUPER + Space` opens a native keyboard launcher on the active monitor; favorites/recents persist safely as user data.
- Bar controls open only matching drawers; switch/backdrop/Escape/invalid IPC/lock all follow close-or-deny behavior.
- Audio, network, system, notification, and session drawers follow their defined safe service behavior, including Cava fallback.
- Each monitor gets a non-blocking task dock obeying the filtering/grouping/chooser rules.
- Default desktop layout is empty, while the same clock package demonstrably renders on bar and desktop after a JSON-only temporary layout change.
- Focused validation and VM evidence pass; installer reruns deploy changed payloads idempotently; uninstall leaves launcher state untouched.
