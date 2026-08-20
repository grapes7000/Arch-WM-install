# Arch WM Shell Design System

## 1. Atmosphere & Identity

The shell is a quiet, wallpaper-first command surface: useful state appears in a centered constellation, while the desktop remains visually present around it. Its signature is the orbit layout: one calm home surface anchors two contextual cards, and uncontained app shortcuts visibly escape the anchor into the wallpaper. Theme changes alter the material and color story without changing this hierarchy.

## 2. Color

### Palette

All colors come from `Core.Theme`, which reads the generated theme-engine contract. Homepage QML must not add literal palette colors.

| Role | QML token | Usage |
|---|---|---|
| Desktop | `Core.Theme.background` | Fallback behind wallpaper |
| Home surface | `Core.Theme.surfaceRaised` | Primary centered surface |
| Context surface | `Core.Theme.surfaceElevated` | Media and activity cards |
| Embedded surface | `Core.Theme.surfaceOverlay` | Progress tracks and compact metric wells |
| Hover surface | `Core.Theme.surfaceHover` | Pointer feedback |
| Primary text | `Core.Theme.foreground` | Titles, values, controls |
| Secondary text | `Core.Theme.muted` | Metadata and inactive labels |
| Primary accent | `Core.Theme.accent` | Active section, primary graph, focus |
| Secondary accent | `Core.Theme.accent2` | Secondary graph and media detail |
| Critical | `Core.Theme.urgent` | High-load and error states only |
| Outline | `Core.Theme.roles.border_subtle` with `Core.Theme.barOutlineColor` fallback | Surface rims and separators |

Colors that need translucency use `Core.Theme.alphaColor(token, alpha)`. Accent is semantic, not decoration: it identifies selection, activity, or actionable state.

## 3. Typography

### Scale

The shell uses `Core.Theme.fontFamily` and derives sizes from `Core.Theme.shellFontSize` so themes can change density coherently.

| Level | QML expression | Usage |
|---|---|---|
| Display | `shellFontSize + 9` | Time and primary metric values |
| H1 | `shellFontSize + 5` | Surface and card titles |
| H2 | `shellFontSize + 3` | Section title |
| Body | `shellFontSize + 1` | Primary labels and search text |
| Body/sm | `shellFontSize` | Navigation and metadata |
| Caption | `max(9, shellFontSize - 1)` | Chart legends and supporting state |

Use bold weight for values and hierarchy, regular weight for supporting copy, and the Nerd Font fallback only for private-use icon glyphs. Text must elide rather than overflow a bounded card.

## 4. Spacing & Layout

### Base Unit

Internal spacing follows a 4 px rhythm. Runtime values may derive from `Core.Theme.gap`, but resolve to multiples of 4 wherever geometry is not constrained by the screen.

| Token | Value | Usage |
|---|---:|---|
| `space-1` | 4 px | Icon-to-label and chart detail |
| `space-2` | 8 px | Compact clusters |
| `space-3` | 12 px | Controls and metric wells |
| `space-4` | 16 px | Card padding |
| `space-5` | 20 px | Surface section spacing |
| `space-6` | 24 px | Large surface padding |
| `space-8` | 32 px | Orbit gutters |

### Orbit Geometry

- The visible homepage cluster is centered within the usable desktop beneath the bar.
- At desktop sizes, the home surface occupies about 46% of available width and 68% of available height, capped to remain near-square.
- Two context cards form a right-hand stack at roughly 25% of available width with a 16–24 px gap.
- Six app shortcuts form a 3-by-2 uncontained cluster below the contextual cards. They stay fully outside card bounds so labels and icons never cover card content.
- The workspace strip sits below the primary surface with enough width for all ten compact workspace indicators, including the expanded active label.
- The desktop wallpaper remains visible through at least 40% of the usable area.
- Under 1180 px width or 720 px height, the cluster reduces gaps and card heights; content stays operable without extending beyond the screen.
- Layout geometry is compositor behavior, not theme data. Material, radius, opacity, outline, color, typography, and motion remain theme-owned.

## 5. Components

### Home Surface Frame

- **Structure**: one continuous `GlassCard`-derived surface containing greeting, search affordance, section toggles, and one changing detail stage.
- **Variants**: standard, compact.
- **Spacing**: `space-4`, `space-5`, `space-6`.
- **States**: visible, hidden-for-window, page transition, unavailable panel.
- **Accessibility**: search and section controls expose pointer and keyboard activation; long content elides.
- **Motion**: surface assembly uses the theme motion scale; detail changes fade rather than move layout.
- **Layout**: vertical stack with a single bounded detail owner.

### Section Toggle

- **Structure**: icon, label, and bottom selection indicator without a surrounding card.
- **Variants**: home, system, network, audio, calendar, media.
- **Spacing**: `space-1`, `space-2`.
- **States**: default, hover, active, keyboard focus, pressed.
- **Accessibility**: minimum 40 px target, visible focus/active indicator, activation by Enter/Space.
- **Motion**: accent and opacity transition using `Core.Theme.homepageTransitionMs` and `motionScale`.
- **Layout**: equal-width horizontal cluster.

### Floating App Shortcut

- **Structure**: app icon and short label rendered directly over the wallpaper; no shared dock or background.
- **Variants**: resolved desktop icon, Nerd Font fallback.
- **Spacing**: `space-1`, `space-3`.
- **States**: default, hover, keyboard focus, pressed, unavailable.
- **Accessibility**: minimum 48 px target and elided label; activation launches only the configured command.
- **Motion**: small theme-scaled lift and press response on transform/opacity only.
- **Layout**: 3-by-2 grid aligned below the contextual stack, with no overlap against card bounds.

### Context Card

- **Structure**: `GlassCard` material with one header and one focused body.
- **Variants**: media, live activity.
- **Spacing**: `space-3`, `space-4`.
- **States**: active, idle, unavailable, high load/error.
- **Accessibility**: controls retain 40 px targets; status never depends on color alone.
- **Motion**: only actionable media controls and live data changes animate.
- **Layout**: right-hand vertical stack.

### Embedded Metric

- **Structure**: icon, label, value, optional progress line.
- **Variants**: primary, secondary, urgent.
- **Spacing**: `space-1`, `space-2`.
- **States**: normal, high, unavailable.
- **Accessibility**: label and value are always both visible.
- **Motion**: progress width changes use the theme transition duration.
- **Layout**: three-column row inside the detail stage.

Existing `GlassCard`, `ProCard`, `MetricTile`, `Sparkline`, and portable widget `Panel.qml` files remain the reusable component foundation. The home surface loads widget panels for Network, Audio, Calendar, and Media rather than duplicating service logic.

## 6. Motion & Interaction

| Type | QML duration | Usage |
|---|---|---|
| Micro | `animationMs * motionScale` | Press and hover feedback |
| Standard | `homepageTransitionMs * motionScale` | Page/content changes |
| Assembly | existing `GlassCard` reveal timing | Homepage appearance |
| Reposition | native `DragHandler` gated by `Qt.MetaModifier` | Super+left-drag moves any floating card within the centered orbit |

Motion communicates selection, activation, or changing system state. It uses transform and opacity where practical, respects `Core.Theme.motionScale`, and becomes immediate when that scale is near zero. No decorative looping animation is added.

The compositor's Super+left-mouse window-drag bind is non-consuming so layer-surface cards can receive the same gesture. The card handler remains disabled without Super, preserving child controls and ordinary pointer behavior. Dragging is bounded to the orbit and is session-local; layout JSON/QML remains the source of the default arrangement.

## 7. Depth & Surface

### Strategy: mixed tonal glass

- The primary surface uses `surfaceRaised` at `homepageCardOpacity`, with a subtle theme outline.
- Context cards use `surfaceElevated`; embedded wells use low-alpha `surfaceOverlay`.
- A one-pixel inner highlight may use the theme outline at reduced alpha.
- Window blur and shadow intent remain owned by the theme/Hyprland pipeline through `blurEnabled`, `blurStrength`, `shadowEnabled`, and `shadowRadius`.
- Floating cards add a two-layer angled silhouette derived from `shadowEnabled`, `shadowRadius`, `shadowColor`, and `shadowOpacity`, plus a restrained `accent2` rim. Themes that disable shadows remove both layers.
- App shortcuts intentionally have no container; their icon shadow/glow is a theme-accent alpha treatment, never a fixed color.

## 8. Accessibility Constraints & Accepted Debt

### Constraints

- Target WCAG 2.2 AA contrast through the theme schema's contrast validation.
- Every new interactive target is at least 40 px in both dimensions and provides hover, press, and visible active/focus feedback.
- Labels supplement every status color and icon.
- Content elides or adapts under compact geometry instead of overflowing.
- Motion respects `Core.Theme.motionScale`; a near-zero value disables non-essential transitions.
- The lock surface never hosts this homepage; the existing lock-state visibility gate remains mandatory.

### Accepted Debt

| Item | Location | Why accepted | Owner / Exit |
|---|---|---|---|
| QML has no screen-reader role coverage in the current shell component layer | Homepage controls | Existing platform-wide limitation; this redesign must not worsen keyboard/pointer reachability | Shell accessibility pass |
