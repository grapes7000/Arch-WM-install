# Todo 1 Contract Adversarial Verification

```json
{
  "type": "AdversarialVerify",
  "verdict": "needs-fix",
  "confidence": 0.96,
  "evidencePaths": [
    ".omo/evidence/shell-feature-integration/task-1-baseline-layouts.txt",
    ".omo/evidence/shell-feature-integration/task-1-red-qml.txt",
    ".omo/evidence/shell-feature-integration/task-1-red-ipc.txt",
    ".omo/evidence/shell-feature-integration/task-1-dirty-worktree.txt",
    ".omo/evidence/shell-feature-integration/task-1-focused-test.txt",
    ".omo/evidence/shell-feature-integration/task-1-layout-validation.txt",
    ".omo/evidence/shell-feature-integration/task-1-qmllint.txt",
    "modules/shell/core/WidgetContext.qml",
    "modules/shell/core/SurfaceRegistry.qml",
    "modules/shell/core/InteractiveShellController.qml",
    "modules/shell/core/ScreenResolver.qml",
    "modules/shell/components/WidgetHost.qml",
    "modules/shell/services/LockStateService.qml",
    "modules/shell/shell.qml",
    "modules/shell/surfaces/bar/BarSurface.qml",
    "modules/shell/surfaces/desktop/DesktopSurface.qml",
    "modules/shell/core/qmldir",
    "modules/shell/services/qmldir",
    "modules/shell/qmldir",
    "tst_shell_control_plane.qml"
  ],
  "exactRepro": [
    "python scripts/validate-layouts.py",
    "find modules/shell -name '*.qml' -print0 | xargs -0 qmllint",
    "qs -p tst_shell_control_plane.qml --no-color",
    "rg -n 'target: \"(launcher|drawers|dock)\"' modules/shell/shell.qml",
    "rg -n 'LockSurface|Lockscreen|LockSurface \\{' modules/shell/core modules/shell/components/WidgetHost.qml modules/shell/services/LockStateService.qml modules/shell/shell.qml modules/shell/surfaces/bar/BarSurface.qml modules/shell/surfaces/desktop/DesktopSurface.qml tst_shell_control_plane.qml",
    "qs list --all"
  ],
  "criterionFindings": {
    "layout_validation": "confirmed: exit 0; three layouts, 11 manifests, and generated registry valid",
    "qml_lint": "confirmed: exit 0 with no output",
    "manual_qa": "confirmed: exit 0, exactly one CONTROL_PLANE_PASS, no CONTROL_PLANE_FAIL; repeated three times with the same result",
    "malformed_locked_hint": "confirmed: harness sets locked=true, rejects malformed input, and proves locked remains true before accepting 'no'",
    "capability_rejection": "confirmed: undeclared capability never reaches the handler; drawer.open is granted only on bar and rejected for desktop and lockscreen",
    "locked_or_absent_controllers": "confirmed by combined runtime and source evidence: runtime returns false while locked; InteractiveShellController.invoke returns false when locked, controller is absent, or action is absent. The harness does not independently isolate the unlocked/absent-controller branch",
    "ipc_targets": "confirmed: shell.qml declares exactly launcher, drawers, and dock target strings",
    "lock_surface_absent": "confirmed: scoped search has no LockSurface/Lockscreen instantiation; shell.qml creates only BarSurface and DesktopSurface",
    "failing_first": "needs-fix: task-1-red-qml.txt predates implementation but fails on missing quickshell-coreplugin under qmltestrunner, an infrastructure/import failure unrelated to the missing request/lock contract. task-1-red-ipc.txt predates shell.qml but records only an empty actual-output body and omits the invocation/exit status, so it is weak and not independently reproducible from the artifact",
    "dirty_worktree": "confirmed: pre-edit artifact records concurrent unrelated changes; current scoped diff does not show destructive cleanup of those changes",
    "slop_overfit": "note: the focused harness is a compact real QuickShell execution and asserts machine-observable booleans, not prose or source deletion. It does combine several behaviors in one scenario, and it does not isolate absent-controller rejection; this is a false-confidence gap, not evidence that production behavior fails. No excessive extraction, parser/normalizer, deletion-only test, tautological expected-value derivation, or >250-pure-LOC scoped module was found"
  }
}
```

## Recommendation

REJECT the Todo 1 evidence claim until the failing-first artifacts are replaced with reproducible failures caused by the absent contract. The current implementation behavior itself is confirmed by the requested commands.

## Blocker

- `violatedCriterion`: `TODO1-FAILING-FIRST-EVIDENCE`
  - Observation: `.omo/evidence/shell-feature-integration/task-1-red-qml.txt` fails because `quickshell-coreplugin` is unavailable to `qmltestrunner`, not because the request/lock contract is missing. `.omo/evidence/shell-feature-integration/task-1-red-ipc.txt` contains neither its command nor exit status and shows an empty actual-output body.
  - `evidencePointer`: `.omo/evidence/shell-feature-integration/task-1-red-qml.txt:5-8`; `.omo/evidence/shell-feature-integration/task-1-red-ipc.txt:1`
  - Required fix: reproduce a red test through the same `qs -p` runtime used for green, with an assertion that fails specifically on the pre-contract behavior; record command, complete output, and exit status. Record the IPC red with the exact invocation, output, and exit status.

## Reproduced Results

- `python scripts/validate-layouts.py`: PASS, exit 0.
- `find modules/shell -name '*.qml' -print0 | xargs -0 qmllint`: PASS, exit 0, no diagnostics.
- `qs -p tst_shell_control_plane.qml --no-color`: PASS, exit 0, contains `CONTROL_PLANE_PASS`, contains no `CONTROL_PLANE_FAIL`.
- Flake probe: three additional runs all exited 0 with one pass marker and no fail marker.
- IPC declaration search: launcher at `shell.qml:17`, drawers at `shell.qml:25`, dock at `shell.qml:34`; no extra scoped target declarations.
- Lock-surface search: no match in the scoped files.

## UltraQA

- `malformed_input`: triggered by `applyLockedHint("malformed")`, invalid drawer kind, and undeclared capability; all reject without unsafe state transition or handler dispatch.
- `stale_state`: triggered by setting locked true before malformed hint; locked state is preserved.
- `dirty_worktree`: triggered; pre-edit artifact and current status show unrelated concurrent work, with no observed destructive reset/revert.
- `misleading_success_output`: triggered; the harness requires exit 0 plus a pass marker and absence of a fail marker. The red QML artifact is misleading as contract evidence because its failure is environmental.
- `prompt_injection`: ruled out; no prompt/model text or external untrusted instruction channel exists in scoped QML inputs.
- `cancel_resume`: ruled out; the self-terminating harness has no resumable state or stage boundary.
- `hung_long_commands`: ruled out; all requested commands completed in under one second in this reproduction.
- `flaky_tests`: ruled out for the observed environment by three consecutive identical harness passes; no timers other than an interval-0 single trigger control the assertions.
- `repeated_interruptions`: ruled out; no interruption occurred during any gate.

## Cleanup Receipt

No non-self-terminating QuickShell instance was started. After the harness and repeat probe, `qs list --all` showed only the pre-existing installed config instance at `/home/lakota/.config/quickshell/arch-wm/shell.qml` (PID 217390). Nothing was killed, and the user session was not locked.

## Notes

- The production contracts are coherent: the registry intersects requested grants with host policy, denies all locked requests, requires a callable handler, and propagates only an explicit `true`; lock state is bound into the controller and both visible surfaces; lock activation closes controller-owned overlays and the bar popup.
- The harness should ideally add a distinct unlocked/absent-controller assertion. The source branch is direct and currently correct, so this is a coverage note rather than a separate blocking production failure.
