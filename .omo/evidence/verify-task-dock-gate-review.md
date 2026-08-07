# Todo 4 dock gate review

recommendation: REJECT

## Original intent

Deliver a desktop-host-owned, per-monitor, auto-hiding task dock that filters mapped Hyprland toplevels by monitor, groups them by desktop/application identity with address fallback, supports single-window activation and multi-window choosing, uses a narrow hidden-state input mask, obeys lock state, and has reproducible focused test/lint/layout plus live layer/screenshot evidence.

## Desired outcome

Each detected screen owns one `arch-wm-task-dock` layer even with an empty desktop layout; only mapped local-monitor windows appear; same-class windows group; remote/stale rows do not; hidden state remains non-blocking; IPC targets the active monitor; lock closes/hides the dock and rejects opening.

## User outcome review

The implementation is coherent and the focused model test, `qmllint`, and layout validator reproduce successfully. Direct source inspection confirms strict monitor-name filtering, mapped/address filtering, startup-class/entry/app/address identity fallback, single-window activation, multi-window chooser selection, hidden/revealed mask switching, active-screen controller routing, and lock visibility/close behavior. The supplied open/closed screenshots visibly show the dock and its absence, respectively.

The evidence package is not ready for the requested draft-PR gate: its live-smoke receipt names an invocation path that does not exist, and the plan-required canonical JSON evidence name is absent. Therefore the live claim cannot be reproduced from its own receipt as written.

## Blockers

1. violatedCriterion: `T4-QA-EVIDENCE` — Todo 4 requires evidence `task-4-dock.{txt,json,png}` and a reproducible live dock QA scenario.
   evidencePointer: `.omo/evidence/shell-feature-integration/task-4-dock.smoke.txt:2` records `qs -p /home/lakota/Arch-wm-install/modules/shell/dock-smoke.qml`, but that path is absent; the actual harness is `.omo/evidence/shell-feature-integration/task-4-dock-smoke.qml`. Also `.omo/evidence/shell-feature-integration/task-4-dock.json` is absent; layer captures instead use `task-4-dock.open-layers.json` and `task-4-dock.closed-layers.json`.

## Notes (non-blocking)

- Open and closed layer JSON are identical. This is compatible with the acceptance requirement that every detected screen retain one dock namespace while the mask/content changes, but layer JSON alone does not establish visual state; the paired screenshots do.
- The QML unit tests cover monitor filtering, grouping, stale rows, and empty identity/address fallback. They do not directly execute single-window activation, chooser interaction, mask geometry, active-monitor IPC routing, or lock transitions. Source inspection supports those paths, but the final VM QA should exercise them.
- Direct remove-ai-slops/programming pass: no needless production extraction, deletion-only test, requested-removal assertion, tautological expected value, or implementation-mirroring helper was found in the scoped dock files. The focused tests are compact and behavior-oriented, though narrower than the full QA matrix.

## Checked artifacts

- `.omo/plans/shell-feature-integration.md`
- `modules/shell/surfaces/desktop/DockModel.qml`
- `modules/shell/surfaces/desktop/TaskDockSurface.qml`
- `modules/shell/surfaces/desktop/TaskDockWindow.qml`
- `modules/shell/core/InteractiveShellController.qml`
- `modules/shell/services/LockStateService.qml`
- `modules/shell/shell.qml`
- `tests/qml/tst_dockmodel.qml`
- `.omo/evidence/shell-feature-integration/task-4-dock-smoke.qml`
- `.omo/evidence/shell-feature-integration/task-4-dock.txt`
- `.omo/evidence/shell-feature-integration/task-4-dock.smoke.txt`
- `.omo/evidence/shell-feature-integration/task-4-dock.open-layers.json`
- `.omo/evidence/shell-feature-integration/task-4-dock.closed-layers.json`
- `.omo/evidence/shell-feature-integration/task-4-dock.png`
- `.omo/evidence/shell-feature-integration/task-4-dock.closed.png`
- `.omo/evidence/shell-feature-integration/task-4-dock.visual-qa.md`

## Reproduced checks

- `QT_QPA_PLATFORM=offscreen qmltestrunner -input tests/qml/tst_dockmodel.qml -import modules/shell` — PASS.
- `qmllint -I modules/shell` over the three dock QML files and `modules/shell/shell.qml` — PASS.
- `python scripts/validate-layouts.py` — PASS; three layouts, 11 manifests, and generated registry valid.

## Exact evidence gaps

- Missing `.omo/evidence/shell-feature-integration/task-4-dock.json` required by the Todo 4 evidence naming contract.
- Recorded live invocation points to missing `modules/shell/dock-smoke.qml`, so the smoke receipt is not independently reproducible without guessing the actual harness path.
