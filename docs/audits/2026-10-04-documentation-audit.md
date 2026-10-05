# Arch-WM-install documentation audit

Reviewed 2026-10-04 (America/Los_Angeles). Repository: [grapes7000/Arch-WM-install](https://github.com/grapes7000/Arch-WM-install). Branch: `main`. Snapshot: `5cd4a57f725a9c40876bbd282419a95bdb47c8d4`.

Prepared for repository publication: **2026-10-04 20:20:52 PDT** (**2026-10-05T03:20:52Z**). This records publication preparation; the reviewed source snapshot remains the commit above.

## Assessment

**Everything is not documented.** The repository has useful architecture and design documents, but its operating documentation is fragmented and partly stale. The most consequential gaps concern installation side effects, the actual theme installation path, configuration replacement and rollback, and the shell's newer interactive features.

Several features have descriptions in `.omo` implementation plans or old QA receipts. Those count as evidence of intended behavior, but are not an accurate, discoverable current user guide. This report distinguishes those from features absent from the public-facing documentation altogether. Inline comments and built-in `--help` describe some details; they do not resolve contradictions in the README.

The source contains three overlapping theme implementations. Only one is used by the normal installer. Treating every bundled theme feature as something the current installer delivers would be misleading.

### Scope and limits

This is a static code-to-documentation audit of the current default-branch snapshot: installer routing/state/profiles, package manifests, desktop profile manager, compositor configuration and scripts, shell entrypoint/services/controllers/interactive surfaces/widgets/layout contracts, bundled theme commands and adapters, terminal payload, CI and smoke-test tooling. Repository inventory contains 455 tracked entries, including 179 under `.omo`; many of those are historical logs/screenshots rather than active product source. Historical plans and QA documents were consulted to distinguish implementation intent from current behavior. Binary screenshots, wallpaper pixels, and the committed worktree gitlink were not treated as current executable source.

No installer, upstream installer, package transaction, service change, desktop activation, or remote write was performed. External theme-repository implementation was not audited here. “Actual behavior” means behavior traceable in this repository's source, not a claim that every QML interaction works in a live Arch session. This is a feature/behavior coverage audit, not a promise that every private helper needs its own documentation.

## What is documented reasonably well

- Architectural separation of theme data, compositor behavior, services, widgets and surface-owned windows: `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/WIDGET-SYSTEM.md`.
- Installer profiles, basic dry-run/resume/doctor commands, ownership/backups, and package-removal opt-in: README and `docs/INSTALLER.md` (subject to corrections below).
- Optional `desktopctl` curated imports, static review, no foreign installer execution, package ownership, outside-session switching and recovery profile: `docs/DESKTOP_PROFILES.md`.
- Semantic appearance tokens and scratch/music/comms workspaces: `docs/SHARED-APPEARANCE.md`.
- Homepage orbit design and session-local Super-dragging: `DESIGN.md`. This behavior is documented, not a new undocumented feature.
- Bundled Theme Studio editing, undo/redo, recovery, previews, custom UI styles and mirroring new themes into a local source repository: `modules/theme-engine/docs/THEME-STUDIO.md`. The missing part is accurately explaining whether the current installer installs this bundle.
- Custom Quickshell lock surface being disabled and Hyprlock owning authentication: README and source.

## Highest-priority findings

### 1. Theme installation is mutable upstream execution, despite pinned-install claims

**Classification: contradictory/stale documentation. Priority: high.**

**Actual:** `install.sh` runs `python -m installer`; `installer/__main__.py` imports `fixed_entry.main`. That applies the Arch-WM patches from `entry.py`, then replaces stage 40 with `fixed_entry.py`'s implementation. It checks `~/.local/bin/theme`, `~/.config/hypr/themes/<requested>.json`, and `~/.config/hypr/generated/.active`. If the executable or requested theme is absent, it shallow-clones `grapes7000/themes`' default branch and executes `bash <temporary>/themes/install.sh --targets full`. It then invokes `theme <requested>`.

**Intended:** let Arch-WM remain a one-command desktop installer while the separate themes repository owns themes.

**Gap:** README's Theme Engine section describes this fetch, but its Status and Upstream imports sections claim a pinned catalog and that runtime never follows mutable upstream. `docs/SHARED-STACK-MIGRATION.md` describes reusing the standalone engine or a built-in compatibility fallback; that is `runtime.py`'s older implementation, not the active stage. The pinned `theme-catalog-sync` bundle also exists, but normal installation does not call it.

**Document:** one authoritative call chain, exact install/check paths, when refresh happens, network dependence, upstream execution authority, and who owns rollback. Do not promise a fixed catalog count for mutable upstream `main`.

Evidence: `installer/__main__.py`; `installer/fixed_entry.py::{theme_check,install_or_refresh_themes,theme_apply,theme_verify,patch_theme_stage}`; `installer/entry.py::patch_runtime`; README Theme Engine/Upstream imports; `docs/SHARED-STACK-MIGRATION.md`.

### 2. ReGreet/greetd changes system login configuration without an operating guide

**Classification: missing user documentation; inline comments only. Priority: high.**

**Actual:** every profile's normal stage sequence includes `75-login`. Packages include `greetd`, `greetd-regreet`, and `cage`. The installer installs `/etc/greetd/config.toml` and `regreet.toml`, a user-side `arch-wm-regreet-theme` helper, and a user-owned/setgid directory `/var/lib/arch-wm-greeter` with group `greeter` and mode `2750`. It publishes CSS/background there, disables `ly@tty2.service`, and enables `greetd.service` with `--force`. It deliberately does not start greetd immediately, to avoid seizing the current graphical VT.

**Intended:** a theme-matched login screen on reboot/login. Cage runs ReGreet on VT1. The configured clock timezone is hard-coded to `America/Los_Angeles`. The watcher republishes on theme-contract modification, once per second; wallpaper choice falls back to a generated one-pixel image.

**Gap:** no current public login-manager setup, customization, recovery or replacement explanation. Neither the original ten-stage contract nor README's normal installation overview names this stage. The disabled previous service and created asset directory are not all represented by reversible ownership metadata.

**Document:** exact system paths, service transition, activation timing, required permissions, clock setting, TTY recovery, and limitations of uninstall. Describe `ARCH_WM_GREETD_ASSET_DIR` as a helper override if intended to be supported.

Evidence: `installer/runtime.py::{login_check,login_apply,login_verify,STAGES}`; `modules/login/greetd/*.toml`; `modules/login/bin/arch-wm-regreet-theme`.

### 3. Desktop/workstation need access to a private dotfiles repository

**Classification: partly documented, prerequisites and side effects missing. Priority: high.**

**Actual:** desktop and workstation profiles specify `git@github.com:grapes7000/dotfiles.git`. Stage `85-dotfiles` installs `chezmoi` and `age` if needed, then runs `chezmoi init --apply <repo>`. Minimal does not configure this stage's repository. The check uses `chezmoi diff`; verification only checks existence of the source directory. This can require SSH authentication, access to the private repository, and any setup/decryption that repository itself needs.

**Intended:** portable terminal/editor configuration comes from Chezmoi rather than this desktop repo.

**Gap:** migration docs name Chezmoi but the public fresh-install instructions do not explain the private dependency or where to configure an alternative. `--noninteractive` does not itself make external authentication or Chezmoi execution noninteractive. Additional packages installed here are not added to the main package ledger in this function; Chezmoi writes are not backed up by `Context.install`.

**Document:** profile differences, authentication prerequisites, actual configuration ownership and recovery boundaries, and how a public user selects their own dotfiles source.

Evidence: `installer/profiles/{desktop,workstation,minimal}.json`; `installer/runtime.py::{dotfiles_check,dotfiles_apply,dotfiles_verify}`.

### 4. Hyprland and Quickshell refreshes replace whole trees, including local customizations

**Classification: undocumented limitation contradicting override expectations. Priority: high.**

**Actual:** `Context.install` backs up then removes the target directory and copies a source tree. Hyprland preserves only `themes` and `wallpapers`; it does not carry across `conf/local.lua` or the persisted `effects-profile` file. Thus a payload refresh can reset local compositor overrides, although their previous contents remain in a backup. Quickshell's checker compares all files and rejects extra target files: a user layout edit or extra file makes the installed tree differ and can cause whole-tree replacement on a normal rerun.

**Intended:** refresh shipped payloads and remove obsolete files while retaining recoverability.

**Gap:** users are told to edit machine-local overrides and layout JSON without a clear warning that subsequent installation may replace them. A backup is not the same as preserving the live override.

**Document:** which paths survive refresh, which reset, how to reapply customizations, and an actual persistent override strategy. Clarify that shell refresh uses byte comparison as well as version files.

Evidence: `installer/runtime.py::{Context.install,HYPR_FOREIGN_DIRECTORIES,hypr_apply,shell_apply}`; `installer/entry.py::{shell_payload_matches,shell_check,hypr_check}`; `modules/hyprland/config/conf/local.lua`.

### 5. Uninstall restores the active run, not the whole installation history

**Classification: incomplete rollback documentation. Priority: high.**

**Actual:** state is `~/.local/state/arch-wm-install/runs/<run>/state.json` with an `active.json` pointer. Normal install creates a new run; uninstall loads only that active run. It disables services that run recorded, removes its created paths and restores its backups. `--remove-packages` runs `pacman -Rns` on that run's recorded packages. A later mostly-no-op run can become active without owning the original installation's files/packages.

**Intended:** reverse tracked operations while keeping package removal explicit.

**Gap:** `docs/INSTALLER.md` shows `./uninstall.sh --restore latest`, but the parser has no `--restore`. It also describes richer state than is actually recorded: current state has no repository revision, file-hash ledger or per-stage version map. Whole-root-owned file restoration uses ordinary filesystem operations in `StateStore.restore`, rather than a sudo-aware restore path; system-file rollback can therefore hit permissions. This is a source-derived limitation, not a tested live rollback failure here.

**Document:** run scope, state paths, actual supported command, retained external theme/Chezmoi/user state, privileged restore limitation, and prior display-manager recovery. Avoid claiming complete rollback of untracked upstream/theme or Chezmoi work.

Evidence: `installer/runtime.py::{Context._run_id,uninstall_command,parser}`; `installer/state.py::{StateStore._load_or_initialize,save,load_active,restore}`; `docs/INSTALLER.md`.

## Other installer and maintenance gaps

| ID | Classification | Actual behavior / intended purpose | Documentation needed |
|---|---|---|---|
| 6 | Missing semantics | `--no-aur` is accepted/stored but has no package/AUR branch. The main installer uses only pacman manifests. | State that no AUR helper is bootstrapped here and this flag currently changes no install behavior. Source: `installer/runtime.py::Options,package_apply,parser`. |
| 7 | Incomplete | Official package installs always use `--noconfirm`, independent of `--noninteractive`. The latter only suppresses `sudo -v` preflight. | Explain automation and prompting behavior; do not imply interactive package approval exists. Source: `runtime.py::preflight_apply,package_apply`. |
| 8 | Missing CLI guide | `--only-stage`, `--from-stage`, and `--verbose` exist. Resume skips completed stages before check/verify, even if payloads or options changed. | List exact stage names, dependencies, and skip semantics. No true per-stage rollback is implemented: Stage defaults to a no-op rollback. Source: `runtime.py::stage_selection,install_command,Stage,parser`. |
| 9 | Missing side effect | If a `tailscale` executable is found, stage 70 automatically enables/starts `tailscaled.service`; Tailscale is not installed by these manifests. | Explain conditional daemon activation, authentication remaining separate, and recorded service ownership. Source: `runtime.py::OPTIONAL_SERVICES,configured_services,services_apply`. |
| 10 | Misleading stage name | `10-repositories` records a note and verifies local modules; it does not sync vendor repositories. Empty vendor directories are correctly acknowledged in UPSTREAMS. | Explain that normal runtime does not consume vendor snapshots, even if sync tooling exists. Source: `runtime.py::repositories_*`; `scripts/sync-upstreams.sh`. |
| 11 | Missing recovery guide | `scripts/force-shell-repair.sh` manually backs up/replaces the shell from a local checkout, kills/restarts Quickshell, waits for a quiet period and checks startup logs. | Invocation/root selection (`ARCH_WM_ROOT`), manual backup/log paths, restart effects and manual restore. It bypasses the normal installer ledger. |
| 12 | Missing utility guide | `scripts/sync-bundled-themes.sh` copies reference palettes and bundled UI styles into theme-engine config, overwriting same-named files. | Manual purpose, destinations, overwrite/backup behavior, compatibility with the standalone engine. It is not a normal installer stage. |
| 13 | Stale framework description | `installer/README.md` recommends nonexistent `cli.py`, `context.py`, `backup.py`, and stage modules. Actual code is runtime plus two patch layers and StateStore. | Replace scaffold instructions with the real call graph, including `fixed_entry.py`. |
| 14 | Stale help guarantees | Docs say help regenerates on every installer run; satisfied/resumed session stages skip regeneration. Help also advertises old theme-catalog paths, calls `term` a managed terminal, and describes `reload-shell` as restarting the shell while bundled alias merely executes Zsh. | Distinguish terminal shell vs Quickshell, external commands vs locally installed commands, cached reference vs checkout-rendered help. Source: `entry.py::session_*`; `help.py`; `modules/terminal/zsh/aliases.zsh`. |

## Shell features present but missing current operating documentation

README's “not yet production-complete” list is a readiness statement, not proof those widgets are absent. It should distinguish implemented-but-unverified behavior from missing implementation. The current registry contains 12 widget packages: workspaces, active-window, clock, media, volume, network, battery, system-stats, notifications, session, weather and tray.

| ID | Feature and evidence | Actual behavior and likely purpose | Documentation status / missing detail |
|---|---|---|---|
| 15 | Launcher: `surfaces/bar/LauncherOverlay.qml`, `services/LauncherStateService.qml` | Searches installed desktop entries by name, generic name, comment and keywords; filters categories; supports list/grid, arrows/Enter, Escape/backdrop dismissal, favorites and 10 recent launches. Grid right-click toggles a favorite. State is atomically written to `$XDG_STATE_HOME/arch-wm-shell/launcher.json`, including `viewMode`; unknown IDs are pruned. | Described in internal plan, absent from current user guide. Explain UI gestures, state/reset path and application-only search: homepage text says “Search apps and files” but this launcher does not search files. |
| 16 | Task dock: `surfaces/desktop/{TaskDockSurface,TaskDockWindow,DockModel}.qml` | Bottom hover reveals a per-monitor dock. Running windows group by desktop identity/class; favorites produce pinned launchers shared with launcher state. Single-window click focuses it; multiple windows show a chooser. Includes mapped windows across that monitor's workspaces. | Internal plan/QA coverage only. Document hover, grouping, pins, multi-window chooser, cross-workspace behavior and IPC. Do not imply thumbnail previews. |
| 17 | Drawers/control center: `BarSurface`, `DrawerController`, `DrawerSurface`, `components/MenuPopup.qml` | Bar widgets open exclusive anchored panels for calendar, audio, network, system, notifications, session, weather and battery. Escape/backdrop closes. The older control center remains, with quick launcher/theme/monitor/home/lock/session actions. | Internal plans are partially stale; one says drawers replace the control center, while implementation preserves it. Need current interaction map and supported drawer names. |
| 18 | IPC: `modules/shell/shell.qml` | Config-scoped targets are launcher, drawers, dock, brightness, audio and homepage. Interactive controller resolves focused monitor with first-screen fallback. Drawer `open` takes a kind; there is no public screen-name parameter in the current shell handler. | Internal contract lists only three targets and an extra drawer argument. Need a reference for actual signatures and returned bool/int values. A method returning `false` is not necessarily a failed CLI exit; historical QA explicitly records this distinction. |
| 19 | Audio: `services/AudioService.qml`, `widgets/volume/Panel.qml` | Native Quickshell PipeWire registry tracks default sink/source, device rows and streams; supports per-node volume/mute and default-device selection. UI service volume is clamped 0–100 and setting it unmutes. | Internal plan says wpctl polling; current service is event-driven. Need prerequisites, controls, defaults and failure states. Hardware volume binds still call wpctl. |
| 20 | Backlight/OSD: `BrightnessService.qml`, `OsdSurface.qml` | Reads preferred sysfs panel, uses logind SetBrightness via busctl, enforces minimum 1%, optimistically updates state. Volume/brightness OSD reacts to underlying changes, arms after 1.2s and lasts 1.4s; appears on each monitor and is hidden while locked. | No operating guide. Explain laptop-panel scope, no external-monitor DDC control, hotkey fallback to brightnessctl, and that an accepted request is not confirmation of a successful busctl write. |
| 21 | Wi-Fi/Bluetooth: `NetworkService.qml`, `BluetoothService.qml`, `widgets/network/Panel.qml` | nmcli polls status/details/scans/radio; user can toggle Wi-Fi, select SSID and submit a password to connect. bluetoothctl powers Bluetooth on/off; this is not a full pairing manager. Password is passed in argv, not through interpolated shell text. Draft clears on network selection/submission. | Internal plan says rich networking but user docs omit setup/actions. Transfer rates are initialized/reset to “Idle” and never sampled: those labels are placeholders. Do not promise measured bandwidth or password secrecy from local process inspection. |
| 22 | VPN/Tailscale status: `TailscaleService.qml` | Polls `tailscale status --json` every 15s, displays tailnet/peer/IP/exit-node info, allows textual status expansion. Mullvad detection is a hostname heuristic; names containing `homelab` are hard-coded as Mullvad-routed exits. | Spec mentions service, no current guide. Explain read-only status, optional dependency, and especially that green/Mullvad labeling is not an egress or leak verification. Put user-specific mappings into local config rather than presenting as universal logic. |
| 23 | Weather: `WeatherService.qml`, `widgets/weather/*` | Fetches current/hourly weather from `wttr.in/?format=j1` every 10 minutes, then sends returned latitude/longitude to Open-Meteo for 10-day forecast. Uses Celsius/km/h; preserves prior good data on some failures. curl has bounded timeouts. | Entirely missing operating/network-source docs beyond “optional weather.” Explain IP-derived location, two external providers, transmitted coordinates, units, refresh, stale readings and lack of a current location/unit preference. |
| 24 | Notifications: `NotificationService.qml` | Uses Dunst history, shows count and five recent items, reads paused state, toggles DND and closes current notifications. It does not replace Dunst as notification daemon. | Only internal plan. Explain dependency, history vs active notification count, dismiss behavior and persistence/privacy boundary. |
| 25 | Session controls: `SessionService.qml`, `widgets/session/Panel.qml` | Lock is immediate. Logout/suspend/reboot/poweroff arm on first click and execute on second same-action click within four seconds. | Internal plan only. Document confirmation timing, cancel behavior, and commands. The existing logout service uses `hyprctl dispatch exit`, distinct from the Lua keybind's fallback. |
| 26 | System/media/Cava: `SystemStatsService`, `MprisService`, `CavaService` | System samples every 5s: CPU over 0.15s, available-memory calculation, root-filesystem utilization, uptime, first readable thermal zone and five ps CPU-ranked processes. playerctl polls media every 3s. Cava streams up to 24 normalized bars and retries after exit. | Internal plan describes most fields, no current data-definition guide. Temperature is not guaranteed CPU temperature, ps process CPU is not the same short interval as CPU gauge, disk metric is capacity utilization. Cava/other polling can remain active when dashboard is hidden. |
| 27 | Homepage visibility/history: `HomepageSurface.qml` | Hard-coded orbit dashboard on each screen, Home/System/Network/Audio/Calendar/Media pages; defaults to System. Auto-fades/hides if active workspace has any toplevel, probes every 600ms. Keeps up to 40 local metric-history samples every 2s while visible. Right-click opens control center; Super-drag is session-local. | Design covers orbit and dragging; user guide omits hide rules, page default, history lifetime and that metric history can repeat underlying 5s samples. Super+D cannot force visibility over open windows because auto-hide is a separate gate. |
| 28 | Legacy desktop layout disabled: `shell.qml`, `LayoutService.qml`, `DesktopSurface.qml` | Current shell instantiates homepage, bar, task dock and OSD. It does not instantiate `DesktopSurface` or custom lock surface. Editing `desktop.default.json` therefore does not change the visible homepage in this default composition. | Contradicts generic JSON-only portability instructions and post-login smoke assumptions. Document active vs opt-in hosts and which layout file each actual surface consumes. |
| 29 | QuickAccessPanel: `surfaces/homepage/QuickAccessPanel.qml` | Reusable component includes apps/places/projects, scanning Git markers under ~/Projects, ~/Code, ~/Developer to bounded depth, max eight results; opens folders or Kitty in project directory. | Missing feature/integration status. Current active homepage composition does not instantiate this component, so this is available source, not a guaranteed visible product feature. |
| 30 | Tray: `TrayService.qml`, `widgets/tray/Widget.qml`, `components/TrayMenu.qml` | Hosts D-Bus StatusNotifier items; passive items dim rather than disappear, attention gets a marker, empty tray collapses. Click/menu/secondary-click/wheel actions route to tray item; menus are surface-owned capability requests. | No current tray operating or compatibility guide. Document SNI scope and allowed surfaces; arbitrary legacy tray protocols are not guaranteed. |
| 31 | UiStyle/font: `core/Theme.qml`, `core/UiStyle.qml` | Theme palette and UI geometry are separate watched files. UI style controls spacing/radii/control sizes/font sizes and none/restrained/playful motion. Current `fontFamily` is hard-coded Inter, even though shell comments say theme UI font. | Theme Studio docs explain style editing but architecture/shared-appearance/design docs still blur ownership. Document precedence, fallback style, motion and fixed font. The manifest does not explicitly include an Inter package. |
| 32 | Runtime validation vs contracts: `WidgetRegistry`, `LayoutService`, `WidgetHost`, `scripts/validate-layouts.py` | Offline validator checks manifest/registry/layout consistency with manual checks, not JSON Schema loading. Runtime parses a smaller subset and keeps last good objects. Host grants capabilities but manifest metadata is not a sandbox for QML code. | Current docs overstate universal schema enforcement and missing-widget diagnostics/edit mode. Explain validator invocation after edits, registry maintenance, runtime check limits and trust model. |

### Actual IPC reference to add to user docs

These describe source APIs; no desktop invocation was performed here.

```bash
qs -c arch-wm ipc call launcher open       # also close, toggle
qs -c arch-wm ipc call drawers open audio  # also calendar/network/system/notifications/session/weather/battery
qs -c arch-wm ipc call drawers close
qs -c arch-wm ipc call dock toggle         # also open, close
qs -c arch-wm ipc call homepage toggle     # also show, hide
qs -c arch-wm ipc call brightness get      # also up, down, set <percent>
qs -c arch-wm ipc call audio mute          # also up, down, micMute, set <percent>
```

Source contract: shell.qml plus `InteractiveShellController.qml`. Brightness/audio handlers call services directly rather than going through the controller's interaction lock guard. Do not document all IPC endpoints as uniformly denied during lock. Homepage changes logical visibility, while lock/window gates still govern actual display.

## Compositor and legacy/bundled theme gaps

### 33. Persisted compositor effects profiles and environment controls lack a guide

`conf/motion.lua` adds `performance`, `balanced`, and default `cinematic` profiles. Selection precedence is persisted `~/.config/hypr/effects-profile`, then `ARCH_WM_EFFECTS_PROFILE`, with `ARCH_WM_LOW_MOTION=1` forcing performance. `effects-profile.py` writes the profile then reloads Hyprland. It shapes springs, dimming, blur, shadows, glow and layer rules; gates motion blur at version >=0.56 and experimental wobble at >=0.57 plus `ARCH_WM_EXPERIMENTAL_WOBBLE=1`.

These are implementation checks, not independently verified upstream API/version guarantees in this audit. “Performance” still enables animation and shadows; it is not a true zero-motion mode. Generated theme loads before motion.lua; the separate theme watcher later applies some settings again, so startup and live-theme precedence need explicit documentation.

Likely intent: separate compositor motion personality/performance from palette. Missing: usage, precedence, exact effects, compatibility baseline, persistence/reset path, and distinction from bundled `theme effects` presets. Source: `modules/hyprland/config/{hyprland.lua,conf/motion.lua,scripts/effects-profile.py,scripts/theme-sync.py}`.

### 34. Autostart/default alias and idle behavior need explicit defaults

Autostart starts polkit agent, nm-applet, udiskie, Hyprpaper, Hypridle, Dunst, ReGreet theme watcher, Hyprland theme watcher, and guarded Quickshell; exports session environment into D-Bus/systemd. `ensure-quickshell-default.sh` creates a relative `default -> arch-wm` symlink only if no default config exists, and preserves conflicting existing defaults. That symlink is created outside the installer's ownership ledger.

Hypridle locks at 300 seconds, turns displays off at 360, locks before sleep and restores DPMS after sleep. Automatic suspend is intentionally absent. Touchpad defaults include natural scroll, tap-to-click and a three-finger workspace gesture. These defaults are mostly code comments rather than a user settings guide. Likely intent: a working first-login desktop with safe idle locking.

### 35. Duplicate Super+L binding is concealed by generated help

`keybinds.lua` registers Super+L for lock and again via the H/J/K/L focus loop for focus-right. Help parser explicitly deduplicates identical keys keeping the first occurrence. Thus “every keybind” help hides the collision. Actual dispatch resolution requires live validation; this audit does not guess which wins. Document/fix the conflict and keep arrow-right as an unambiguous focus path. This is a behavior/documentation mismatch, not an absent feature.

### 36. Bundled Firefox/Obsidian/GTK adapters already mutate app config

`theme_runtime.apply_theme` in the bundled Studio runtime unconditionally calls `_apply_app_themes`: finds Firefox-family native/Flatpak profiles, writes `chrome/theme-engine.css`, inserts a userChrome import, and appends the stylesheet-enabling preference to user.js. It finds registered Obsidian vaults, writes `.obsidian/snippets/theme-engine.css`, and adds the snippet to appearance.json. `theme_components.apply_apps` adds managed GTK3/GTK4 CSS blocks. The app-theming plan discusses these as future phased adapters and proposes target switches not implemented by this code.

Likely intent: propagate semantic colors without wholesale replacement of existing settings. Missing: current activation policy, affected files/products/vaults, disable/cleanup/restart procedure, first-write backup status and optional-failure behavior. These writers do not implement the plan's first-mutation backups, and optional app I/O failures can propagate. This is **bundled runtime behavior**, not evidence that normal Arch-WM installation deploys or uses it; the standalone upstream engine was outside audit scope.

### 37. Semantic wallpaper tools have a substantial undocumented CLI

Bundled `wallgen semantic` supports list/use/none/import/apply, importing an image into dominant-color regions mapped to theme roles, region-count/min-percent options, suggested-role autoaccept, nonactivating import and live `--set`. It preserves antialiasing during color transformation and stores reusable template data. README only shows `wallgen --all` and simple theme wallpapers.

Likely intent: recolor a reusable source image from semantic palette roles. Add a dedicated guide with file locations, import/activation flow, reset, dependency on Pillow and difference from classic generated blobs. Helpers `THEME_WALLGEN_COMMAND`/`THEME_LEGACY_COMMAND` are additional undocumented bundled runtime overrides.

### 38. Eww code remains despite the no-Eww narrative

`modules/theme-engine/bin/theme_homepage.py` is a substantial Eww homepage implementation: generates Eww configs, uses `~/.config/eww/homepage`, launches a dedicated Eww daemon/window, tracks its PID and stops it. The current default shell does not call it, and main installer does not deploy this Studio module. Nevertheless it is committed code that conflicts with statements implying no Eww implementation is retained.

The Eww path checker only searches filenames/directories containing “eww”, not file contents or command use. Consequently it passes while this Python file contains Eww implementation. Likely intent: a carried-over legacy helper, not the active Quickshell dashboard. Document it explicitly as inactive legacy debt or remove it; distinguish “Eww is not required by the active installation” from “the repository contains no Eww code.”

### 39. Portable terminal bundle needs clear legacy status

`modules/terminal` includes Kitty split/navigation/search/hints bindings, copy-on-select, transparency and cursor trail; Atuin fuzzy history with auto-sync/update checking disabled; Zsh modern-tool aliases and temporary-directory helper; `term` actions history/files/git/monitor/theme/system/doctor/shortcuts. Comments explain many settings, but no consolidated operating reference exists.

Current installer delegates terminal configuration to external dotfiles and does not install this bundle. Help/keybinds still rely on `term`, and the minimal profile has no dotfiles apply. Therefore installation does not itself guarantee that these external commands/configs exist merely because packages or bundled files exist. Document dormant bundle vs expected external interface and minimal-profile behavior. Bundled `term doctor` checks `ARCH_WM_REPO` but does not change cwd or set PYTHONPATH before `python -m installer`; it can fail outside a checkout even when the root path exists.

## Optional desktop profile manager: good guide, remaining omissions

### 40. Command/reference and scanner limitations

The current guide covers the main workflow well but omits practical details of `audit`, `status`, `fetch --refresh`, `activate-pending --apply`, `restore --apply`, and `remove <profile> --apply [--remove-packages]`. `--json` is a global argparse option and belongs before the subcommand, for example `desktopctl --json status`. `--allow-aur` is reserved and ignored by the v0.1 flow.

`plan` can auto-fetch if source is missing, so not every “read” operation is network-free or filesystem-free. `fetch --refresh` deletes the old source clone. Profiles follow named refs (`main` or `mainstream`) and record resolved commit at preparation; this is not a predefined immutable commit pin.

Scanner is regex/line-based, skips comment-prefixed lines, binary/unrecognized suffixes and text over 2MB, and rejects symlink escapes. Audit gates findings only under curated copied prefixes, preserving excluded findings for review; prepare rescans the staged payload. This is useful conservative screening, not arbitrary-code safety proof. Prepared QML/compositor configuration can execute commands later when the desktop is launched, despite the importer not executing it during preparation.

Runtime/capability/protected metadata is largely descriptive; version requirements are not proven by an executable runtime-version compatibility check. Existing `qs` presence controls provider reuse. Document these limits rather than describing metadata as enforcement. Evidence: `desktop_manager/{cli,manager,scanner,models,codex_review}.py`; `desktop_manager/profiles/*.json`.

### 41. Monitor snapshots and recovery storage

Selecting a foreign profile requires a captured monitor snapshot; normally run selection inside the working Arch-WM session. Stored snapshot can be reused later. Activation generates a Lua monitor overlay in the prepared profile. First activation captures Arch-WM once; later edits do not automatically recapture that recovery profile. `launch --apply` activates config then execs Hyprland, so a profile activation can succeed before launch fails.

Storage roots are `$XDG_DATA_HOME/arch-wm-install/desktop-profiles` (sources, payloads, backups) and `$XDG_STATE_HOME/arch-wm-install/desktop-profiles` (registry, package ledger, saved theme targets, switch journal). Catchable activation errors attempt rollback; abrupt process/machine termination is the documented crash-recovery gap. Add recovery/cleanup examples and clarify snapshot freshness. Source: `manager.py::{Paths,select,_capture_arch,_monitors,activate_pending,launch}`.

## Tests, CI and documentation discrepancies

Checks executed against the unmodified snapshot:

| Check | Result | Interpretation |
|---|---|---|
| `python -m unittest discover -s tests` | 130 tests passed | Main suite, including installer/profile-manager and structural checks. Does not prove a live Arch install. |
| `python scripts/validate-layouts.py` | 3 layouts, 12 widget manifests and generated registry valid | Offline manual contract checks. |
| `python -m unittest discover -s modules/theme-engine/tests` | 18 tests run; 1 error | `test_full_apply_still_invokes_legacy` calls sibling wallgen; subprocess raises PermissionError because the file is not executable. Git records wallgen mode 100644. |
| Bash syntax checks for entrypoints/scripts/term/theme-install/theme-menu | Passed | Syntax only. |
| `bash scripts/check-legacy-widget-free.sh` | Passed | Names-only check; does not detect Eww code described in finding 38. |
| QML runtime/lint, Lua lint, fresh Arch VM, reboot/rollback/login | Not run | Required tooling/live desktop not present in this audit environment. Historical receipts were not counted as a new live test. |

Additional documentation/test gaps:

- CI's “Run installer and theme tests” step discovers only `tests/`; it does not run the separate bundled Theme Studio test directory. This explains why the extra-suite error can coexist with a green main suite.
- CI validates the old pinned bundled catalog, while the normal installer uses mutable standalone upstream. That validates a different installation path.
- CI QML lint lists selected shell files, not all service/widget/dock QML, and does not run the QML behavioral tests under `tests/qml` or root `tst_shell_control_plane.qml`.
- `vm-smoke-test.sh post-login` checks clock entries in bar/desktop JSON. The desktop host is disabled, so this does not prove the same widget renders on the live desktop. It also checks older theme-output paths that should be reconciled with the active standalone engine.
- Some `.omo` historical receipts report 11 manifests or 17 tests; current snapshot has 12 manifests and 130 main tests. Keep them as dated evidence, not current totals or acceptance guarantees.
- `docs/SHELL-MOTION-ROADMAP.md` contains uncompleted checklists for behavior partially implemented in GlassCard/homepage. Update implementation status; planned draggable edit/snap features should remain distinct from existing session-local Super-drag.
- README clone instructions point to an implementation branch, while this audit is of main. Make the recommended checkout explicit and verify instructions for that branch rather than mixing snapshots.

## Recommended documentation work

1. Rewrite README installation/status/theme sections around `fixed_entry.main`, public prerequisites, ReGreet and Chezmoi. Separate delivered, experimental and inactive bundled functionality.
2. Replace scaffold installer docs with real stage names/options/state paths and a truthful rollback/customization-preservation guide.
3. Add `docs/SHELL-USER-GUIDE.md`: launcher/favorites/state, dock, drawers/control center, IPC signatures, OSD, weather providers/units, Tailscale heuristics, session confirmation and unavailable states.
4. Add `docs/CONFIGURATION.md`: theme vs UiStyle vs compositor effects precedence, actual font behavior, monitor/local override lifecycle, layouts/registry maintenance and idle defaults.
5. Mark bundled themes/terminal/Eww helpers as legacy or optional development code until a documented supported installation path exists. Update app-theming/semantic-wallpaper docs around their current code, separately from the standalone upstream product.
6. Add a compact testing matrix explaining what Python tests, layout checks, QML tests, CI and a fresh VM each prove. Retire stale smoke assumptions and include the separate Theme Studio suite when its bundle is still maintained.

The repo's architectural intent is clear. The main documentation problem is that historical plans, compatibility code and the active runtime are presented as one product state. Correcting those boundaries will make the existing features substantially easier to use and maintain.

## Pinned source links

These links resolve to the audited commit, so later main-branch changes will not alter the evidence.

- [installer/__main__.py, line 1](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/installer/__main__.py#L1)
- [installer/fixed_entry.py, line 41](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/installer/fixed_entry.py#L41)
- [installer/runtime.py, line 528](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/installer/runtime.py#L528)
- [installer/runtime.py, line 582](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/installer/runtime.py#L582)
- [installer/runtime.py, line 168](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/installer/runtime.py#L168)
- [installer/entry.py, line 132](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/installer/entry.py#L132)
- [installer/runtime.py, line 709](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/installer/runtime.py#L709)
- [installer/state.py, line 187](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/installer/state.py#L187)
- [modules/shell/shell.qml, line 11](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/modules/shell/shell.qml#L11)
- [modules/shell/services/LauncherStateService.qml, line 10](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/modules/shell/services/LauncherStateService.qml#L10)
- [modules/shell/surfaces/desktop/DockModel.qml, line 249](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/modules/shell/surfaces/desktop/DockModel.qml#L249)
- [modules/shell/services/WeatherService.qml, line 195](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/modules/shell/services/WeatherService.qml#L195)
- [modules/shell/services/TailscaleService.qml, line 25](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/modules/shell/services/TailscaleService.qml#L25)
- [modules/shell/core/Theme.qml, line 187](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/modules/shell/core/Theme.qml#L187)
- [modules/hyprland/config/conf/motion.lua, line 7](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/modules/hyprland/config/conf/motion.lua#L7)
- [modules/theme-engine/bin/theme_runtime.py, line 264](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/modules/theme-engine/bin/theme_runtime.py#L264)
- [modules/theme-engine/bin/theme_homepage.py, line 732](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/modules/theme-engine/bin/theme_homepage.py#L732)
- [modules/theme-engine/bin/wallgen, line 468](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/modules/theme-engine/bin/wallgen#L468)
- [desktop_manager/manager.py, line 626](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/desktop_manager/manager.py#L626)
- [.github/workflows/validate.yml, line 17](https://github.com/grapes7000/Arch-WM-install/blob/5cd4a57f725a9c40876bbd282419a95bdb47c8d4/.github/workflows/validate.yml#L17)


## Follow-up: Quickshell and Hyprland organization

The desktop is reasonably separated by responsibility, but ownership of theme effects and legacy configuration paths needs cleanup. This is a static architecture assessment, not a live-session validation.

| Location | Responsibility | Interaction |
| --- | --- | --- |
| `modules/shell` | Quickshell QML surfaces, widgets, shared services, controllers, and layout contracts | Reads Hyprland state, requests workspace/window actions, and exposes IPC for launcher, homepage, and brightness controls |
| `modules/hyprland/config` | Compositor configuration, monitors, input, window rules, keybindings, autostart, and compositor adapters | Starts Quickshell and invokes its IPC from keybindings |
| Theme contract | Shared generated theme data | Quickshell consumes `theme.json`; Hyprland adapters translate theme data into compositor settings |

The shell has useful internal boundaries (`core`, `services`, `components`, `widgets`, `surfaces`, and `layouts`), and its entrypoint mainly assembles surfaces. Audio/network/media services belong in the shell and do not themselves indicate inappropriate mixing with compositor configuration. Hyprland owns window management; Quickshell owns the visible desktop controls. Authentication remains with Hyprlock, while the custom shell lock surface is disabled.

The main organizational weaknesses are:

1. **Multiple owners of compositor appearance.** Generated theme Lua, `conf/motion.lua`, and live `theme-sync.py` can affect overlapping blur, shadow, and animation settings. Precedence is harder to understand than the directory split suggests.
2. **Legacy and active paths coexist.** Older `.conf` files, newer Lua configuration, bundled theme generators, and the external runtime theme installation path make it unclear which source is authoritative without tracing the installer. Bundled theme generation also emits Hyprland configuration, crossing the intended adapter boundary.
3. **Some shell contracts are duplicated or bypassed.** Drawer/widget identifiers appear in several controllers and surfaces. Homepage placement is implemented directly in QML rather than following the portable layout contract, while older disabled desktop layout machinery remains.
4. **Configuration lifecycle needs a clearer boundary.** Refreshing installation replaces configuration trees; a `local.lua` override is not automatically protected by that separation. Personal overrides should have an explicitly preserved location.

Recommended order: establish one owner and documented precedence for compositor effects; label or remove inactive configuration paths; consolidate shell widget/drawer metadata; then preserve and document user overrides. The current structure is a solid basis for this cleanup, but it is not yet consistently organized end to end.
