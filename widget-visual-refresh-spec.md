# Widget Visual Refresh — Spec

**Request:** Make every shell widget look as good as the network widget, both when opened from the bar and on the homepage. Network (with its colored boxes, status tinting, blinking "CONNECTED" pill, and progress ring) is the reference design the user wants extended across the widget set.

**Status:** Spec only. No code changes yet.

---

## 1. Current state (from codebase research)

### 1.1 Where widgets render

| Context | Host | How a widget appears |
|---|---|---|
| Bar (compact) | `modules/shell/surfaces/bar/BarSurface.qml` | `WidgetHost` instances from `layouts/bar.default.json`; each loads the widget's `Widget.qml` with a `context` (variant `compact`) |
| Bar drawer (clicked) | `modules/shell/components/MenuPopup.qml` | `PanelWindow`; a `Loader` loads `widgets/<kind>/Panel.qml` with **no context/variant passed** |
| Homepage | `modules/shell/surfaces/homepage/HomepageSurface.qml` | Bespoke cards; only the "network" page loads `network/Panel.qml` via `networkPanelLoader`. Other pages (system, audio, calendar, media) show **placeholder text** in a `GlassCard`. |
| Lock screen | `modules/shell/surfaces/lockscreen/LockSurface.qml` | **Disabled** (`enabled: false`); safe to treat as a future constraint, not a deliverable. |

### 1.2 Panel coverage today

| Widget | `Panel.qml`? | Quality |
|---|---|---|
| network | ✅ | **Reference design** — tinted boxes, green active tint, blinking pill, Canvas progress ring, transfer pill, expandable sections |
| weather | ✅ | Fleshed out (tabs, StatChips, hourly/10-day) |
| media | ✅ | Basic (visualizer bars, circular play button, volume slider row) |
| system-stats | ✅ | Basic (stat bars + uptime) |
| volume | ❌ | **Clicking opens an EMPTY drawer** |
| notifications | ❌ | **Empty drawer** |
| session | ❌ | **Empty drawer** |
| battery | ❌ | **Empty drawer** |
| clock | ❌ | **Empty drawer** |
| workspaces | ❌ | **Empty drawer** (widget has rich `Widget.qml` boxes but no panel) |
| active-window | ❌ | **Empty drawer** |

Note: the MenuPopup overview has a volume row with **no click handler** (no `MouseArea`), so volume can't be opened from the drawer overview at all today.

### 1.3 The network design language (reference)

Deconstructed from `network/Panel.qml`:

1. **Tinted cards** — `Rectangle` with `radius: Math.max(6, Core.Theme.radius - 2)`, fill `Qt.rgba(1,1,1,0.04)`, border `Qt.rgba(1,1,1,0.06)`.
2. **Status-aware tinting** — active state swaps fill/border to a colored tint (e.g. Mullvad green `rgba(0.2,0.8,0.4,0.06)` / border `rgba(0.2,0.8,0.4,0.3)`); inactive sections drop to `opacity: 0.4–0.5`.
3. **Blinking status pill** — `radius: 999` pill ("CONNECTED"/"OFF") with a 1500 ms repeating `Timer` toggling a `pulseState`; opacity animates 1.0 ↔ 0.6 over 750 ms (`Easing.InOutQuad`).
4. **Canvas progress ring** — `Canvas` arc ring showing a percentage with the value centered (wifi strength).
5. **Transfer/stat pill** — full-width `radius: 999` bar with two muted values.
6. **Expandable sections** — header row (chevron + bold title + trailing action) that toggles content; password input row appears inline.
7. **Icon + title + subtitle rows** — large Nerd Font glyph, bold 13 px title, muted 10 px subtitle.

### 1.4 Services available to back richer panels

- **AudioService** — `volume`, `muted`, `sinks[]`, `sources[]`, `streams[]` (per-device volume/mute/default), `setVolume`, `setSinkVolume`, `toggleMute`, `setDefaultSink`.
- **NotificationService** — `count`, `dndEnabled`, `recent[]` (last 5: appName/summary/body), `dismiss()`, `toggleDnd()`.
- **PowerService** — `percent`, `charging`, `timeRemaining`, `available`.
- **SessionService** — `lock()`, `logout()`, `suspend()`, `reboot()`, `poweroff()`, `cancel()`, `pendingAction` (built-in 4 s confirm pattern), `busy`, `error`.
- **TimeService** — `timeShort/Long`, `dateShort/Long`, `date` (Date object for calendar math).
- **MprisService** — status/title/artist/artUrl/canPrev/canNext + play controls.
- **CavaService** — `bars` (visualizer magnitudes, used by homepage + media panel already).
- **SystemStatsService** — cpu/memory/disk percent + uptime.
- **TailscaleService / NetworkService / WeatherService** — already wired.

### 1.5 Theme tokens (from `core/Theme.qml`)

`Core.Theme` exposes: `background`, `surfaceBase`, `surfaceRaised`, `surfaceElevated`, `surfaceOverlay`, `surfaceHover`, `surface` (alias), `foreground`, `muted`, `accent`, `accent2`, `urgent`, `selected`, `radius`, `borderWidth`, `animationMs`, `motionScale`, `animationProfile`, `fontFamily`, plus raw `roles` (e.g. `roles.border_normal`) and `style` objects. Themes are hot-reloaded from `~/.config/theme-engine/generated/theme.json`.

---

## 2. Decisions (from interview)

### 2.1 Scope
- **Priority set (build first):** volume/audio, notifications, session, clock/calendar, battery.
- **Later phase:** workspaces, active-window, and upgrading media + system-stats panels to full parity.
- **Surfaces:** bar drawer, homepage, **and** the compact bar icons themselves.
- **Theme source:** theme tokens **only** — no hardcoded `rgba(1,1,1,0.04)` white-tints or fixed green tints in new code. Tint constants must be derived from `Core.Theme` tokens (see §4.4) so every theme (e.g. `y2k`) restyles the panels automatically.

### 2.2 Design language
- **Status pill:** only for real binary states (muted, DND, charging, playing, connected). No pills for non-binary states.
- **Color:** a single theme accent (`Core.Theme.accent`) for all active states; `Core.Theme.urgent` only for genuinely critical states (low battery, high CPU). No per-widget hue mapping.
- **Shared components:** build a reusable design-system library under `modules/shell/components` (StatusPill, TintedCard, ProgressRing, StatChip, SectionHeader, EmptyState) and **refactor network to use it** (visual result must be identical). New panels are assembled from these components.
- **Animation:** more subtle than network — slower/gentler pulses, smaller opacity range, fewer moving parts. Duration/range derived from theme tokens where sensible.

### 2.3 Content
- **Volume panel:** master volume slider + mute pill + now-playing visualizer. (No per-device mixers or stream list.)
- **Notifications panel:** DND toggle + recent notifications list (`NotificationService.recent`).
- **Session panel:** big action buttons with confirm-on-second-click (lock/logout/suspend/reboot/poweroff) using `SessionService.confirm`/`pendingAction`.
- **Clock panel:** calendar month grid with today highlighted + date header.
- **Battery panel:** charge ring + percent, time remaining, charging status pill.
- **Empty states:** dimmed placeholder card (icon + message), consistent with network's dimmed inactive boxes.

### 2.4 Hosting & context
- **Context-aware panels:** `Panel.qml` files gain an optional `context` property (mirroring `Widget.qml`) so the same file adapts between the bar drawer (`standard`) and the homepage (`expanded`). Plumbing required:
  - `MenuPopup.qml` Loader → pass `context` (variant `standard`) to `Panel.qml`.
  - `HomepageSurface.qml` panel Loader → pass `context` (variant `expanded`) for the network page and the new pages.
- **Homepage form:** reuse the same `Panel.qml` files with expanded variants (single source of truth).
- **Compact icons (bar):** tinted box on hover, colored border when active — the workspaces-slot treatment, applied to the compact `Widget.qml` variants. Glyph + label stay.

### 2.5 Lock screen
- The lock surface is **currently disabled**. Spec decision: when it ships, allow a limited **read-only** version of panels (status only, no controls). Not a deliverable of this refresh; noted as a constraint so components don't hard-depend on interactive capabilities. Panels must degrade gracefully under `context.locked === true` (hide control surfaces, show status).

### 2.6 Testing
- **QML tests for components** using the existing QML test setup (`tests/qml/`). Pure logic (calendar math, ring fraction, pill state mapping) must be unit-testable.

### 2.7 Build order
1. Shared component library (+ port network onto it, visually identical).
2. **Volume/audio panel** — the template that sets the patterns for the rest.
3. Notifications, clock/calendar, battery, session.
4. Compact bar icon treatment.
5. Homepage wiring for new pages (context-aware Loader, expanded variants).
6. Later phase: workspaces, active-window, media/system-stats parity.

---

## 3. Architecture

### 3.1 New shared components (`modules/shell/components/`)

| Component | Purpose | Replaces |
|---|---|---|
| `TintedCard.qml` | Theme-derived tinted card: base fill, border, radius, opacity, optional status tint + dim | network's `Rectangle` cards |
| `StatusPill.qml` | Pill with label + `active` state; optional gentle pulse timer; reads `Core.Theme` | network's blinking CONNECTED pill |
| `ProgressRing.qml` | Canvas arc ring + centered value; theme colors | network's wifi strength ring |
| `StatChip.qml` | Small label/value box | weather's `StatChip` (consider consolidating) |
| `SectionHeader.qml` | Chevron + title + trailing action row | network's expandable headers |
| `EmptyState.qml` | Dimmed placeholder card (icon + message) | the "nothing to show" case |

Design requirements:
- All colors resolved from `Core.Theme` (see §4.4 for tint derivation).
- `radius`/spacing follow `Core.Theme.radius`; all interactive elements get `cursorShape: Qt.PointingHandCursor` and hover states where sensible.
- Components must be safe under `locked: true` (no interactive element required for rendering).

### 3.2 Context-aware panel loading

`Panel.qml` files accept a `context` object with the same shape as `Widget.qml` (variant defaults to `"standard"`), plus a `density`-driven scale factor so `expanded` variants can grow on the homepage.

- **MenuPopup:** Loader gets `context: { variant: "standard", ... }` when instantiating the panel.
- **Homepage:** replace the placeholder `GlassCard` text pages for system/audio/calendar/media with a shared `Loader` (like `networkPanelLoader`) that loads the matching `Panel.qml` with `variant: "expanded"`. Add the volume/notifications/battery/session pages if the homepage page model grows (currently: home, system, network, audio, calendar, media — map: audio→volume panel, calendar→clock panel, system→system-stats panel, media→media panel).

### 3.3 Compact bar icons

Apply the workspaces-slot treatment to compact variants of volume, notifications, network, battery, weather, session, system-stats:
- A `Rectangle` box that is transparent at rest, shows a `Core.Theme.surface`/hover tint on hover, and gains an accent border/fill when the widget is in an "active" state (connected, playing, DND, charging, urgent).
- Keep glyph + text; wrap existing content in the box. Must not change the bar height or layout metrics (works with existing `WidgetHost` sizing).

---

## 4. Per-widget panel specs

### 4.1 Volume / audio panel (`widgets/volume/Panel.qml`) — FIRST, template

- **Header card:** speaker icon (state-aware glyph) + bold title + `StatusPill` ("MUTED" when muted, "PLAYING"/"PAUSED" when media active) + master percentage.
- **Master volume slider:** full-width pill-track slider (like MenuPopup's volume bar but interactive/draggable), fill `Core.Theme.accent`, mute state → muted color. Wire to `AudioService.setVolume` / `toggleMute`.
- **Now-playing visualizer:** reuse the media panel's animated bar row (CavaService or MprisService-driven), shown only when media is active; subdued per §2.2 animation rules.
- **Empty state:** when no audio devices exist (`AudioService.error`), dimmed `EmptyState` card.

### 4.2 Notifications panel (`widgets/notifications/Panel.qml`)

- **Header card:** bell glyph + count + `StatusPill` ("DND" when on) + dismiss-all action (`dismiss()`).
- **Recent list:** up to 5 items from `NotificationService.recent` (app name, summary, body) as compact rows in a `TintedCard`.
- **Empty state:** "No notifications" dimmed card.

### 4.3 Clock / calendar panel (`widgets/clock/Panel.qml`)

- **Header card:** big time + date.
- **Calendar month grid:** 7-column grid, correct weekday alignment, today highlighted with `Core.Theme.accent` (computed from `TimeService.date`; logic isolated for unit testing).
- Prev/next month controls optional — **ask in implementation** or default to no navigation (spec default: no navigation, month of today only, keep simple).

### 4.4 Battery panel (`widgets/battery/Panel.qml`)

- **Charge ring:** `ProgressRing` showing `PowerService.percent`, color → `urgent` when ≤15 % and discharging.
- **Status pill:** "CHARGING" when charging (gentle pulse), "FULL" when full.
- **Details row:** time remaining + percent in a stat pill.
- **Empty state:** dimmed card when `!PowerService.available`.

### 4.5 Session panel (`widgets/session/Panel.qml`)

- **Action grid:** lock / logout / suspend / reboot / poweroff as large buttons in `TintedCard`s.
- **Confirm-on-second-click:** first click arms the button (shows "Confirm?" state, accent border), second click fires `SessionService.confirm(...)`; `SessionService.pendingAction` + 4 s timer already implement this — surface its state visually. `cancel()` on escape/click elsewhere.
- Poweroff in `Core.Theme.urgent`.
- Respect `context.locked` (read-only if ever shown on lock surface).

### 4.6 Later phase

- **Workspaces panel:** list of Hyprland workspaces (id, name/icon from the widget's slot table, focused/active state) with click-to-activate.
- **Active-window panel:** window title + class/app info.
- **Media panel upgrade:** art URL thumbnail + title/artist + visualizer + transport controls, restyled onto shared components.
- **System-stats panel upgrade:** move `StatBar` onto `StatChip`/shared components, add per-bar health coloring.

### 4.7 Homepage additions

- New pages use the same `Panel.qml` files at `variant: "expanded"` (audio→volume, calendar→clock, system→system-stats, media→media; network stays as-is but gets the context pass).
- If a page's panel is not yet built (e.g. during phased rollout), keep the current placeholder text as a graceful fallback.

---

## 5. Theme-token derivation rules (no hardcoded tints)

New panels must not contain literal `Qt.rgba(1,1,1,0.04)`-style constants. Instead:

- **Card base tint:** derive from `Core.Theme.surfaceRaised`/`surfaceElevated` (or `foreground` at low alpha, e.g. `Qt.color(Core.Theme.foreground)` → `Qt.rgba(r,g,b,0.04)`), keeping the value theme-aware.
- **Active tint:** `Qt.color(Core.Theme.accent)` at low alpha (e.g. 0.06–0.12 fill, 0.3 border).
- **Critical tint:** `Core.Theme.urgent` at low alpha.
- **Borders:** `Core.Theme.accent2` (matching existing `GlassCard`/bar border convention) or `Core.Theme.roles.border_normal`.
- **Dimming:** opacity 0.4–0.5 on inactive/empty states (keep network's range).
- Animation durations multiply `Core.Theme.animationMs` and respect `Core.Theme.motionScale` (per §2.2, keep pulse intervals ≥ 2 s and opacity range ≤ 0.5 swing for "subtle" feel).

A helper (e.g. `Core.Theme.tint(color, alpha)` or a `ThemeTint` component) may be added to keep this ergonomic — validate against the existing `ColorAnimation`/`Behavior` usage.

---

## 6. Acceptance criteria

1. Clicking **volume, notifications, session, battery, clock** in the bar opens a filled, themed panel (no empty drawers). Media/system-stats panels remain functional during the transition.
2. Panels render identically in the bar drawer (`standard`) and on the homepage (`expanded`), reusing the same `Panel.qml` files.
3. Homepage placeholder pages for audio/calendar are replaced by real panels; remaining placeholders are only for not-yet-built widgets.
4. Compact bar icons gain the hover-box + active-border treatment without changing bar metrics.
5. The network panel's visual output is unchanged after being ported onto shared components (visual regression check).
6. `theme y2k` (or any theme swap) restyles all new panels via tokens — no hardcoded colors in new/changed files.
7. All new components have QML tests; calendar/ring/pill pure logic covered. Existing tests (`tests/qml/*`, `test_shell_services.py`) still pass; `scripts/check-legacy-widget-free.sh` unaffected.
8. Panels never crash when their service is unavailable — always render the dimmed `EmptyState`.
9. Lock-screen read-only posture: no new component hard-requires interactivity.

---

## 7. Risks / open questions

- **Homepage page model:** the homepage only has system/network/audio/calendar/media pages today; battery/notifications/session have no homepage page. Decide during implementation whether to add pages or keep them drawer-only.
- **Calendar navigation:** spec defaults to no month navigation; trivially extensible later.
- **Slider interaction:** Qt Quick Controls `Slider` availability in this Quickshell/Qt version must be verified; fall back to a custom `MouseArea` slider (project currently hand-rolls sliders elsewhere).
- **CavaService reuse:** the visualizer already exists in two places (homepage, media panel); the volume panel should reuse the same pattern — consider extracting a shared `Visualizer` component in the same pass.
- **Network refactor risk:** porting network to shared components must be byte-for-byte visually equivalent; do it as a separate, reviewable commit before building new panels on the components.

---

## 8. Suggested implementation sequence

1. `TintedCard`, `StatusPill`, `ProgressRing`, `EmptyState` (+ `Theme` tint helper) + QML tests.
2. Port `network/Panel.qml` onto components; visual diff vs current.
3. Build `volume/Panel.qml` (template) + compact icon treatment for volume.
4. Panels: notifications → clock → battery → session (each + compact treatment + tests).
5. MenuPopup context pass + homepage context-aware Loader; wire new pages.
6. Media + system-stats parity; workspaces + active-window panels (later phase).
7. Full visual QA in drawer + homepage; run `tests/`, `qmllint` (see `.omo` evidence patterns), theme-swap check.
