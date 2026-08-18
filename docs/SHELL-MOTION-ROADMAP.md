---
title: Arch WM Shell Motion Roadmap
aliases:
  - Shell Motion Roadmap
  - Quickshell Animation Roadmap
tags:
  - arch-wm
  - quickshell
  - hyprland
  - motion-design
  - roadmap
status: active
updated: 2026-08-18
---

# Arch WM Shell Motion Roadmap

> [!summary]
> The goal is not to add animation for its own sake. The shell should use Quickshell/QML and Hyprland as a coordinated spatial interface: controls should visibly come from somewhere, surfaces should transform rather than teleport, widgets should preserve identity across bar/homepage/desktop states, and compositor motion should reinforce the shell instead of competing with it.

## Design principles

1. **Spatial continuity over fades.** Prefer movement, resize, shared-origin expansion, and spring settling over unrelated fade-in/fade-out transitions.
2. **Quickshell owns shell-internal motion.** QML should animate widget geometry, opacity, scale, transforms, panel contents, drag states, and shell surfaces.
3. **Hyprland owns compositor motion.** Window/workspace/special-workspace movement, focus transitions, border animation, layer/window entrance styles, and fullscreen behavior should remain compositor-level when possible.
4. **Never animate layout-owned geometry directly when a transform will do.** Qt Quick Layouts may overwrite `x`, `y`, `width`, and `height`; use `Translate`, `Scale`, opacity, wrappers, or explicit non-layout layers for choreography.
5. **Motion must remain interruptible.** If the user opens/closes a surface quickly, animations should reverse or restart safely rather than queueing stale states.
6. **Motion must have a reduced-motion path.** Every major transition needs either a zero/short-duration fallback or a global motion scale.
7. **No unbounded animation loops by default.** Continuous shaders, border rotations, polling animations, or visualizers must stop when hidden and should not force constant compositor frames unnecessarily.
8. **State survives reloads where appropriate.** Floating positions, dock order, panel mode, and widget form should be persisted separately from transient animation state.

## Technical foundation

### Proposed motion tokens

Create a shared QML singleton such as `core/Motion.qml` rather than scattering magic durations throughout the shell.

```qml
pragma Singleton
import QtQuick

QtObject {
    property real scale: 1.0
    readonly property bool reduced: scale <= 0.05

    readonly property int micro: Math.round(90 * scale)
    readonly property int fast: Math.round(150 * scale)
    readonly property int normal: Math.round(220 * scale)
    readonly property int panel: Math.round(340 * scale)
    readonly property int scene: Math.round(480 * scale)

    readonly property int staggerSmall: Math.round(55 * scale)
    readonly property int staggerPanel: Math.round(90 * scale)

    readonly property real liftScale: 1.025
    readonly property real pressScale: 0.96
    readonly property real overshoot: 1.08
}
```

Recommended first-pass timing language:

| Motion class | Duration | Character |
|---|---:|---|
| Micro control | 70–120 ms | immediate, no bounce |
| Hover/press | 100–160 ms | crisp |
| Popup | 160–240 ms | small overshoot |
| Panel/card | 280–420 ms | spring/back easing |
| Homepage/overview scene | 400–650 ms | staggered choreography |
| Workspace/window | Hyprland-owned | consistent compositor curve |

### Shared animation scaffolding

Prefer small reusable helpers rather than bespoke animation blocks everywhere:

- `Motion.qml` — timing, scale, reduced-motion state.
- `RevealTransform.qml` — target item, progress, translate/scale/opacity mapping.
- `SpringDrop.qml` — drop/settle behavior for detachable panels.
- `SharedOrigin.qml` — records source rect for bar-to-popup morphs.
- `MotionCoordinator.qml` — optional scene-level event coordinator for overview/homepage/dock transitions.
- `PositionStore.qml` — persistent desktop widget coordinates and docking metadata.

### Testing contract for animated features

Every feature should have static/regression tests where practical:

- QML syntax/lint must pass for all touched files.
- Existing Python/unittest suite must remain green.
- New structural tests should assert required motion objects, state handlers, and reduced-motion hooks exist.
- No layout-managed item may animate `x`/`y` directly unless intentionally removed from a Qt Quick Layout.
- Hidden surfaces must stop timers/visualizers/continuous animations.
- Repeated show/hide calls must not leak objects or leave surfaces half-visible.
- Cold Quickshell start and repeated restart remain part of acceptance because this repo has previously hit native startup/reentrancy failures.

---

# 20 planned features

## 1. Homepage assembly choreography

**Status:** implementation target for this branch.

### Experience

When the homepage becomes visible, it should assemble itself instead of appearing as one static slab:

1. background surface fades in;
2. left rail falls into place;
3. center column follows;
4. right rail follows;
5. each major column overshoots slightly and settles;
6. repeated homepage reveals replay the choreography without recreating the whole shell.

The intent is a controlled mechanical assembly, not a cartoon bounce.

### First implementation

- Add `assemblyProgress` properties to the three top-level homepage columns.
- Apply layout-safe `Translate` transforms plus opacity/scale derived from progress.
- Use one scene-level `ParallelAnimation` containing staggered `SequentialAnimation` tracks.
- Use `Easing.OutBack` for the final settling motion.
- Trigger on homepage visibility transitions.
- Reset progress before replaying.
- Do not animate layout-owned `y` directly.

### Later refinement

- Stage individual cards inside each rail after the main column lands.
- Give hero artwork a slower scale-in while Quick Access has a shorter snap.
- Allow themes to tune motion intensity without rewriting the animation.

### Acceptance

- No geometry jump after animation completes.
- Works in compact and full layouts.
- Replay works after `SUPER+D` hide/show.
- Replay works after homepage returns when the last window closes.
- No new Quickshell warnings.

---

## 2. Detachable / floating homepage mode

### Experience

Homepage has two states:

- **Docked:** current structured dashboard.
- **Floating:** outer dashboard frame recedes and its major cards detach into independent desktop surfaces.

An `Assemble` action restores them to the homepage.

### Technical plan

- Add `HomepageModeService` with `Docked`, `Transitioning`, `Floating` states.
- Move reusable dashboard cards into portable components rather than leaving all card content inline in `HomepageSurface.qml`.
- Use a temporary transition layer that snapshots source geometry before reparenting/detaching.
- Persist floating positions in JSON under `~/.config/quickshell/arch-wm/state/` or XDG state.
- Desktop floating surfaces should use Quickshell layer surfaces with no exclusive zone.

### Risk

Reparenting live QML items can break bindings. Safer architecture may be shared state + two render hosts, with a shared-element transition layer bridging them visually.

---

## 3. Physical widget drop and snap

### Experience

Dragged widgets retain velocity, overshoot a snap target, and settle with spring-like movement.

### Technical plan

- `DragHandler` owns pointer movement while editing.
- Store last movement delta/time to estimate release velocity.
- After release, transition from direct manipulation to spring/smoothed animation.
- Snap zones expose rectangles and priority.
- Clamp widgets to visible screen bounds before persistence.

### Guardrails

- Disable inertia for accessibility/reduced motion.
- Do not let a thrown widget become unreachable off-screen.

---

## 4. Bar-widget to popup morphs

### Experience

Clock pill grows into the calendar panel. Network/status pill grows into Quick Settings. Closing reverses into the source pill.

### Technical plan

- Source widget publishes global rectangle and corner radius.
- Popup opens at source geometry using `PopupWindow` anchor information.
- A transition shell interpolates rect/radius/background before revealing detailed popup content.
- On close, reverse and only destroy/hide after reaching source geometry.

### Architecture

Create a shared `MorphPopupHost` so each widget does not implement its own geometry engine.

---

## 5. Adaptive / breathing bar

### Experience

The bar changes density based on state:

- idle widgets contract;
- hover reveals extra information;
- active media expands into a compact now-playing capsule;
- urgent states briefly widen or highlight;
- fullscreen mode collapses the bar.

### Technical plan

- Give each bar widget `compactWidth`, `activeWidth`, and `expandedWidth` states.
- Animate width only inside a non-layout wrapper or use `Layout.preferredWidth` carefully with a single owning Behavior.
- Avoid every widget independently changing size at once; use a bar density coordinator.

---

## 6. GNOME-style kinetic Overview

### Experience

`SUPER` / overview action transforms the desktop into a workspace/window overview with search and dock integration.

### Technical plan

- Quickshell creates overlay UI, search field, workspace representations, and dock.
- Hyprland remains the source of truth for real workspaces/toplevels.
- Avoid synchronous rebuilding from live `Hyprland.toplevels`; preserve the deferred-update pattern already required for Quickshell stability.
- Use cached window metadata and thumbnails/surfaces only through APIs proven safe for this Quickshell version.
- Synchronize overview open/close with Hyprland workspace animations rather than duplicating them.

### Performance target

Opening Overview should not start expensive subprocesses or block the UI thread.

---

## 7. Special-workspace utility drawer

### Experience

A side or top “utility dimension” contains terminal, file manager, calculator, clipboard, notes, etc.

### Technical plan

- Use a named Hyprland special workspace for real application windows.
- Quickshell renders the handle, backdrop, labels, and transition chrome.
- Hyprland animates the actual workspace movement.
- Provide declarative configuration for which apps launch into the utility workspace.

---

## 8. Contextual window choreography

### Experience

Different window classes enter appropriately:

- terminal: small pop/slide;
- settings: side entrance;
- transient dialog: short scale-in;
- scratchpad: top drop;
- picture-in-picture: corner pop.

### Technical plan

- Hyprland window rules classify app classes/titles.
- Use compositor animation styles instead of shell-level fake window animation.
- Keep number of distinct motion families small so the desktop still feels coherent.

---

## 9. Informational active-border animation

### Experience

Window borders communicate transitions without permanent distraction:

- focus change: one short gradient sweep;
- urgent: one pulse;
- completion/attention: optional accent sweep.

### Technical plan

- Hyprland owns border-angle/border color animation.
- Trigger finite events, not permanent rotating borders.
- Expose shell events through a small command/service layer rather than editing config on every event.

### Performance note

Avoid continuously animated border angles because they can force ongoing compositor frames.

---

## 10. Living system dashboard

### Experience

CPU, memory, network, disk, temperatures, and battery show motion/history rather than static percentages.

### Technical plan

- Shared service keeps bounded ring buffers of samples.
- QML Canvas/Shape/Repeater renders sparklines.
- Use `SmoothedAnimation` for displayed current values.
- Sampling frequency scales down when dashboard is hidden.
- Clicking a metric may open `btop`/system monitor.

---

## 11. Gesture-first shell controls

### Experience

- wheel on volume changes volume;
- wheel on workspace pill switches workspaces;
- vertical drag on brightness/volume adjusts continuously;
- horizontal swipe changes workspace/page;
- pinch can enter/exit overview where hardware support is reliable.

### Technical plan

Use Qt Quick handlers (`WheelHandler`, `DragHandler`, `PinchHandler`, `TapHandler`, `HoverHandler`) rather than nested MouseAreas where possible.

### Guardrails

Gesture conflicts need explicit arbitration. Scrolling inside a popup must not accidentally change workspaces.

---

## 12. Magnetic desktop docking

### Experience

Floating widgets reveal guide lines and softly snap to neighboring edges, grid lines, and named zones.

### Technical plan

- Maintain a list of candidate snap rectangles.
- While dragging, compute nearest horizontal/vertical edge under threshold.
- Render temporary alignment guides in a top edit layer.
- On release, spring to selected target.
- `Alt` temporarily disables snapping.

---

## 13. Multi-form widgets

### Experience

One widget can exist as several forms without duplicating logic:

- media: bar chip → popup → desktop card → large player;
- weather: icon → compact forecast → homepage card;
- system: tiny percentages → dashboard graph panel.

### Technical plan

- Separate service/state from presentation.
- Use manifest variants plus a shared model/context.
- Keep actions and capability checks identical across forms.
- Add explicit form metadata such as `compact`, `standard`, `expanded`, `hero`.

---

## 14. Throw-away and drag-to-action interactions

### Experience

- swipe notification away with momentum;
- drag app onto dock to pin;
- drag widget into trash zone to remove from desktop;
- drag popup item toward another surface to transfer it.

### Technical plan

- Pointer velocity + threshold decides commit/cancel.
- Destructive actions require a clear drop target.
- Removal should update persistent layout only after the animation commits.
- Accessibility path must exist without drag gestures.

---

## 15. Selective shader effects

### Experience

Use shaders as accents, not as a permanent GPU tax:

- slight glass/noise texture;
- audio-reactive glow;
- transition wipe/distortion for special scenes;
- theme-colored background bloom.

### Technical plan

- Put shader effects behind a capability/performance toggle.
- Animate shader parameters only while visible.
- Keep a non-shader fallback.
- Profile software-rendered VM behavior separately from real GPU behavior.

---

## 16. Fullscreen/maximize-aware shell

### Experience

- maximized window: bar becomes thinner/flatter;
- fullscreen: bar slides away;
- pointer at top edge: bar reveals with spring tension;
- leaving fullscreen restores normal bar density.

### Technical plan

- Observe focused toplevel state through a deferred service, not synchronous mutation of live Hyprland collections.
- Bar has explicit `normal`, `maximized`, `fullscreenReveal` states.
- Panel exclusive zone changes only after visual transition reaches a safe state to avoid window geometry oscillation.

---

## 17. Desktop gravity / lift mode

### Experience

Entering edit mode makes widgets lift off the desktop. Dropping them produces a tiny squash/settle. Assembling the homepage pulls them back into their slots.

### Technical plan

- Edit state raises z-order, scale, and shadow.
- Drop animation uses translate + scale rather than changing saved geometry mid-spring.
- Persist only final settled coordinates.
- Pair with features 2, 3, and 12.

---

## 18. Global motion profiles

### Experience

Users/themes can select motion character independently of colors:

- `minimal` — short, almost no overshoot;
- `smooth` — GNOME-like ease;
- `spring` — default shell personality;
- `dramatic` — larger stagger and distance;
- `reduced` — near-instant state changes.

### Technical plan

Add motion tokens to a dedicated QML singleton and optionally allow the theme contract to override safe scalar values such as duration scale, drop distance, and overshoot strength.

Do **not** let arbitrary theme JSON inject QML/easing code.

---

## 19. Cross-surface choreography coordinator

### Experience

Multiple surfaces act as one scene. Example: opening Overview simultaneously dims homepage, lifts dock, contracts bar controls, and reveals workspace cards in a coordinated order.

### Technical plan

Create a `MotionCoordinator` singleton with semantic events/states rather than direct item references:

```qml
MotionCoordinator.scene = "overview"
MotionCoordinator.phase = "entering"
```

Surfaces subscribe and animate their local representation. This avoids a giant controller reaching into every QML object.

### Guardrail

Coordinator should express **state**, not micromanage every frame. Each surface owns its own implementation.

---

## 20. Motion inspector and performance guardrails

### Experience

A developer-only inspector shows:

- current scene/state;
- active animations;
- animation duration scale;
- visible shell surfaces;
- polling services currently active;
- optional frame-time/FPS information if available;
- buttons to replay homepage/overview transitions.

### Technical plan

- Add an IPC/debug command such as `qs ipc call archWm motion-debug` or a hidden developer panel.
- Count long-running animation/timer states explicitly in QML where feasible.
- Provide one toggle to disable expensive shader/continuous animation features.
- Add a “replay transition” hook for deterministic visual testing.

This feature is important because the project intentionally wants to use animation heavily; observability keeps that ambition from turning into unexplained battery/GPU usage or hard-to-reproduce timing bugs.

---

# Suggested implementation sequence

## Phase 1 — establish motion language

1. Homepage assembly choreography.
2. Global motion profiles/tokens.
3. Adaptive bar.
4. Bar → popup morphs.
5. Living system graphs.

## Phase 2 — spatial shell

6. Detachable/floating homepage.
7. Physical drop/snap.
8. Magnetic docking.
9. Desktop gravity/edit mode.
10. Multi-form widgets.

## Phase 3 — desktop-level choreography

11. Kinetic Overview.
12. Overview dock/search integration.
13. Special-workspace utility drawer.
14. Fullscreen/maximize-aware shell.
15. Contextual Hyprland window choreography.

## Phase 4 — advanced interaction/polish

16. Gesture-first controls.
17. Throw-away interactions.
18. Informational border events.
19. Selective shaders.
20. Motion inspector/performance tooling.

# Feature 1 implementation checklist

- [ ] Add layout-safe assembly progress to left/center/right homepage columns.
- [ ] Add staggered scene animation with a small bounce/overshoot.
- [ ] Fade the homepage background independently underneath the panels.
- [ ] Replay on homepage visibility changes.
- [ ] Avoid replay while the homepage is hidden behind an open window.
- [ ] Ensure animation properties settle exactly at identity (`opacity: 1`, `scale: 1`, `translate.y: 0`).
- [ ] Add static tests for the choreography and layout-safe transforms.
- [ ] Run full repo unittest suite.
- [ ] Run theme-engine tests if touched by shared infrastructure.
- [ ] Run QML syntax/lint checks on every touched QML file.
- [ ] Confirm branch CI passes before marking complete.
- [ ] Keep this document updated as later features graduate from plan to implementation.
