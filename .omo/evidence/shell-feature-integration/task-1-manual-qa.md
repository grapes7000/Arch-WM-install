# Todo 1 Manual QA

## manualQa

### surfaceEvidence

| scenario id | criterion reference | surface | exact invocation | verdict | artifactRefs |
|---|---|---|---|---|---|
| T1-S1 | Todo 1 acceptance: IPC targets | QuickShell terminal IPC | `qs -p modules/shell ipc show` while `qs -p modules/shell --no-color` is running | PASS — exactly `launcher`, `drawers`, and `dock` targets | A1, A2 |
| T1-S2 | Todo 1 failure QA: invalid call creates no layer | QuickShell IPC + Hyprland layer observability | Capture `hyprctl layers -j`; run `qs -p modules/shell ipc call drawers open invalid`; capture `hyprctl layers -j` immediately after | PASS — IPC output is `false`; sorted namespaces are identical | A3, A4, A5, A6 |

### adversarialCases

| scenario id | criterion reference | adversarial class | expected behavior | verdict | artifactRefs |
|---|---|---|---|---|---|
| T1-A1 | Todo 1 invalid/locked calls open nothing | malformed_input (invalid kind) | Invalid drawer kind returns false and creates no layer | PASS | A3, A4, A5 |
| T1-A2 | Todo 1 invalid/locked calls open nothing | misleading_success_output | Exit 0 is insufficient; output must be false and layers unchanged | PASS | A4, A5, A6 |
| T1-A3 | QA ultraqa | dirty_worktree | Record unrelated dirty state without changing product files | PASS | A7 |
| T1-A4 | QA ultraqa | stale_state | No temporary path-config instance before launch or after teardown | PASS | A8, A9 |
| T1-A5 | QA ultraqa | repeated_interruptions | Teardown must kill the temporary instance and converge to zero stale instances | PASS | A8, A9, A10 |
| T1-A6 | QA ultraqa | prompt_injection | Not applicable: no untrusted prompt/content is consumed by this terminal scenario | not_applicable | A1 |
| T1-A7 | QA ultraqa | cancel_resume | Not applicable: no cancel/resume API is exercised; signal cleanup is covered separately | not_applicable | A8 |
| T1-A8 | QA ultraqa | hung_long_commands | Not applicable: startup and both IPC calls completed synchronously without a hang | not_applicable | A1, A4 |
| T1-A9 | QA ultraqa | flaky_tests | Not applicable: this is a direct live IPC run, not a retryable test harness | not_applicable | A1, A4, A5 |

### artifactRefs

| id | kind | description | path |
|---|---|---|---|
| A1 | terminal transcript | Full exact invocations, outputs, readiness, dirty-worktree, and cleanup receipt | `.omo/evidence/shell-feature-integration/task-1-live-adversarial.txt` |
| A2 | terminal output | IPC target listing | `.omo/evidence/shell-feature-integration/task-1-live-adversarial-ipc-show-final.txt` |
| A3 | JSON | Layer snapshot immediately before malformed IPC | `.omo/evidence/shell-feature-integration/task-1-live-adversarial-invalid-before-final.json` |
| A4 | terminal output | Malformed IPC returned `false` | `.omo/evidence/shell-feature-integration/task-1-live-adversarial-invalid-call-final.txt` |
| A5 | JSON | Layer snapshot immediately after malformed IPC | `.omo/evidence/shell-feature-integration/task-1-live-adversarial-invalid-after-final.json` |
| A6 | diff | Sorted namespace comparison; empty diff / exit 0 | `.omo/evidence/shell-feature-integration/task-1-live-adversarial-namespaces-final.diff` |
| A7 | terminal output | Dirty-worktree snapshot recorded before QA | `.omo/evidence/shell-feature-integration/task-1-live-adversarial-dirty-worktree.txt` |
| A8 | terminal output | Preflight and final `qs list --all` state | `.omo/evidence/shell-feature-integration/task-1-live-adversarial-pre-list.txt` |
| A9 | terminal output | Post-kill convergence with zero temporary instances | `.omo/evidence/shell-feature-integration/task-1-live-adversarial-final-list-check-1.txt` |
| A10 | JSON | Final converged Hyprland layers after teardown | `.omo/evidence/shell-feature-integration/task-1-live-adversarial-final-layers-converged.json` |
