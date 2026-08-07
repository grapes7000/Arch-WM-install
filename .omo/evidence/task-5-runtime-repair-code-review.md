# Code review: task-5-runtime-repair

## Verdict

- `codeQualityStatus`: WATCH
- `recommendation`: APPROVE
- Independent delivery verdict: **confirmed**
- Blockers: none

## Scope and evidence inspected

Current runtime source was inspected directly, including:

- `modules/shell/shell.qml`
- `modules/shell/core/InteractiveShellController.qml`
- `modules/shell/core/ScreenResolver.qml`
- `modules/shell/core/SurfaceRegistry.qml`
- `modules/shell/core/WidgetContext.qml`
- `modules/shell/components/WidgetHost.qml`
- `modules/shell/components/MenuPopup.qml`
- `modules/shell/surfaces/bar/{BarSurface,LauncherOverlay,LauncherSession,DrawerController,DrawerSurface}.qml`
- `tests/qml/tst_drawers.qml` and `tests/qml/tst_launcher.qml`
- `.omo/evidence/shell-feature-integration/task-5-runtime-repair.json`
- `.omo/evidence/shell-feature-integration/task-5-runtime-repair.txt`
- `.omo/evidence/shell-feature-integration/task-5-runtime-repair.cleanup.txt`
- `.omo/evidence/shell-feature-integration/task-5-runtime-repair.lock-{red,green}.txt`
- `.omo/evidence/shell-feature-integration/task-5-runtime-repair.png`

The supplied JSON is internally supported by its text/cleanup artifacts. The captured PNG is a valid `680x642` RGBA image and visually shows an unobstructed, rendered MenuPopup. It is not a substitute for compositor-level lock verification, but it does support the claimed popup preservation.

## Confirmed behavior

- The pre-existing `MenuPopup` remains instantiated and its bar trigger remains active at `modules/shell/surfaces/bar/BarSurface.qml:14` and `:186-194`.
- Launcher and drawer IPC endpoints are registered in `modules/shell/shell.qml:16-31`.
- `LauncherOverlay` and `DrawerSurface` register their live controllers with the shared control plane at `modules/shell/surfaces/bar/LauncherOverlay.qml:86-92` and `modules/shell/surfaces/bar/DrawerSurface.qml:26-31`.
- The drawer surface is a full overlay, uses exclusive keyboard focus while visible, and clears state on close/lock at `modules/shell/surfaces/bar/DrawerSurface.qml:33-99` and `DrawerController.qml:34-45`.
- Locking centrally closes the launcher, drawer, and preserved MenuPopup at `modules/shell/core/InteractiveShellController.qml:81-90`; the red/green receipts show the formerly missing popup-close behavior was corrected.
- Capability routing is present end-to-end: `drawer.open` is allowed only for the bar (`SurfaceRegistry.qml:6-31`), passed through `WidgetContext.request()` (`WidgetContext.qml:19-28`), and dispatched only by the bar host (`BarSurface.qml:31-35`). The lock-screen allowlist excludes it.
- A whole-tree `qmllint -I modules/shell` run exited 0, which also found no stale QML type/import references. `python scripts/validate-layouts.py` reported 3 layouts and 11 manifests valid. Local focused QML tests passed: drawers 4/0 and launcher 3/0.
- Malformed drawer kind, stale-state close, lock close, and the IPC false-body/zero-exit condition are explicitly represented in the supplied evidence. The cleanup receipt initially records an over-broad process matcher false positive, then records the corrected exact process check; no remaining temporary runtime process is asserted by the corrected receipt.

## Findings

### CRITICAL

None.

### HIGH

None.

### MEDIUM

1. Drawer-kind knowledge is duplicated across `InteractiveShellController.qml:13-21`, `DrawerController.qml:12-20`, and `DrawerSurface.qml:11-19`. A future kind change can silently diverge: the IPC/control plane may accept a kind that has no loader (or vice versa). This is currently synchronized and does not invalidate this repair, but it is a regression-risk maintenance seam.

2. The focused tests exercise `DrawerController` and `LauncherSession` in isolation (`tests/qml/tst_drawers.qml:17-50`, `tests/qml/tst_launcher.qml:17-29`); they do not directly exercise `InteractiveShellController` registration/exclusivity or the MenuPopup close callback. The supplied runtime evidence covers those interactions, so this is not an approval blocker, but a later behavioral change can regress that integration without a focused test catching it.

### LOW

None.

## Required skill-perspective check

Ran: yes. I read and applied `omo:remove-ai-slops` and `omo:programming` before judging test relevance and maintainability.

- `remove-ai-slops`: no deletion-only test, tautological test, or test that merely mirrors a removal was found. The added tests assert observable controller/session state transitions, though their integration coverage is limited as noted above. No needless parsing, normalization, or data extraction was introduced.
- `programming`: no untyped escape hatch in a typed source language, prompt test, or needless production parsing was introduced. The QML controller is intentionally a small coordination boundary. The duplicated kind lists are the only maintainability concern found under this perspective.

## Worktree note

The worktree is materially dirty with concurrent shell/theme work. The reviewed repair paths coexist with that work; no claim of a clean worktree is made. `git diff --check` reports pre-existing/in-scope trailing blank-line diagnostics across numerous modified widget files, not a functional failure of the runtime repair.

