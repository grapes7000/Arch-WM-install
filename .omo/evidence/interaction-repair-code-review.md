+# Code review — interaction repair

## Verdict

- codeQualityStatus: WATCH
- recommendation: APPROVE
- confidence: medium
- skill-perspective check: ran. I read and applied `omo:remove-ai-slops` and `omo:programming`.
- remove-ai-slops result: production diff contains no needless parsing, normalization, extraction, or abstraction. The new structure tests do contain deletion/request-text and implementation-mirroring assertions (MEDIUM below).
- programming result: no untyped escape hatches or needless production abstraction were introduced. The test approach is brittle because it asserts QML text/ordering rather than observable interaction (MEDIUM below).

## Scope and evidence inspected

Reviewed the six changed files in the task scope with `git diff HEAD`, the source deployment version checks in `installer/entry.py:169-222`, and the supplied `.omo/evidence/interaction-repair/` artifacts. The worktree is dirty only in the six scoped files plus untracked `.omo/`; no unrelated tracked edits were included in this judgment.

Fresh checks run by this review:

- `git diff --check HEAD` — pass
- `qmllint -I modules/shell modules/shell/components/MenuPopup.qml modules/shell/surfaces/bar/BarSurface.qml` — pass
- `bash -n scripts/vm-smoke-test.sh` — pass
- `python -m unittest discover -s tests -v` — pass (17 tests)

## Confirmed behavior

- `modules/hyprland/config/conf/autostart.lua:16` uses the required exact guarded command: `qs --no-duplicate --config arch-wm`.
- `modules/shell/components/MenuPopup.qml:17-26` turns the popup into a transparent four-edge surface while preserving the 340px top-right card at lines 56-69.
- `MenuPopup.qml:28-40` centralizes reset logic in `close()`, and trigger toggling delegates its close branch to it.
- `MenuPopup.qml:42-75` gives the backdrop dismissal behavior and places the card above it with an event-consuming shield, so clicks inside the card do not reach the backdrop.
- `MenuPopup.qml:48-54` supplies a focused Escape handler. This is source- and parse-validated, not live-interaction validated.
- Version sentinels contain the requested values: `modules/hyprland/config/.arch-wm-version:1` is `2026.08.04.3`; `modules/shell/.arch-wm-version:1` is `2026.08.06.5`. `installer/entry.py:169-222` compares these sentinels against installed managed payloads, so a normal installer run will redeploy stale managed Hyprland and shell configurations.
- `scripts/vm-smoke-test.sh:67-78` launches guarded Quickshell, lists all instances, and requires exactly one literal matching config-path entry.

## Findings

### CRITICAL

None.

### HIGH

None.

### MEDIUM

1. `tests/test_structure.py:83-116` is a brittle, implementation-mirroring suite rather than an interaction regression suite. It asserts source phrases, child ids, a particular sibling arrangement, the absence of the old command, and the literal width. Those checks can pass while focus delivery, pointer dispatch, or the `qs list --all` output contract is wrong; they also fail after behavior-preserving QML refactors. This violates both the remove-ai-slops test-quality perspective (deletion/request-text checks) and the programming perspective (brittle prompt/text tests). It is not a release blocker because direct `qmllint` and the actual smoke-script syntax test pass, but a VM or QML interaction test should lock backdrop, Escape, and card-click behavior by executing them.

2. The supplied `.omo/evidence/interaction-repair/verification-report.md` explicitly says that live deployment/restart was not run. Therefore its claimed popup success is static inspection only. The current implementation is plausible and parses, but there is no artifact proving the real compositor receives Escape or that click stacking works on the target Quickshell version. This is a coverage/evidence gap, not a demonstrated code defect.

### LOW

1. `scripts/force-shell-repair.sh:41` (outside the changed-file scope) still starts `qs -c arch-wm`, rather than the guarded invocation used by the repaired autostart and smoke paths. The normal installer version sentinels are correct, and the script kills the config first, so this does not invalidate the scoped repair; it is nevertheless a stale alternate launch path worth aligning in a separately scoped change.

## Blockers

None. No CRITICAL or HIGH finding remains. The supplied evidence includes concrete artifact paths, so there is no misleading-success-output blocker; its live-QA limitation is documented above.

