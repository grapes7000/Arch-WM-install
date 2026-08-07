# Interaction repair — manual QA

Fresh run: 2026-08-05/06 UTC in the active Hyprland session (`WAYLAND_DISPLAY=wayland-1`). No product files were edited during QA.

## manualQa

### surfaceEvidence

| scenario id | criterion reference | surface | exact invocation | verdict | artifactRefs |
|---|---|---|---|---|---|
| DEPLOY-50 | changed managed stage 50 | installer/Hyprland | `python -m installer install --only-stage 50-hyprland --profile desktop --theme y2k --noninteractive` | PASS (exit 0; subsequent run reported already satisfied) | `deploy-50`, `sentinels` |
| DEPLOY-60 | changed managed stage 60 | installer/Quickshell | `python -m installer install --only-stage 60-quickshell --profile desktop --theme y2k --noninteractive` | PASS (exit 0; subsequent run reported already satisfied) | `deploy-60`, `sentinels` |
| LIVE-INSTANCE | exactly one replacement shell | Quickshell process registry | `qs list --all`; `pgrep -a qs`; `ps -o pid,ppid,stat,cmd -p 217390` | PASS — one `/home/lakota/.config/quickshell/arch-wm/shell.qml`, PID 217390, PPID 1, `qs --daemonize --no-duplicate --config arch-wm` | `final-daemon`, `live-qs-log` |
| LIVE-BAR | one 44px top bar, no duplicate bar | Hyprland layer tree + desktop screenshot | `hyprctl layers -j`; `grim desktop-closed-daemon.png` | PASS — one bar layer at x=4,y=4,w=1912,h=44; screenshot shows one inset top bar | `layers-closed`, `closed-shot` |
| LIVE-DESKTOP | distinguish desktop surface from control-center | Hyprland layer tree + screenshot crop | `hyprctl layers -j`; inspect `desktop-topright-crop.png`; compare `DesktopSurface.qml` geometry | PASS — 340x274 x=1576,y=56 matches DesktopSurface top-right geometry; closed screenshot has no full-screen control-center card | `layers-closed`, `closed-shot`, `topright-crop` |
| DUPLICATE-GUARD | second guarded start leaves count at one | Quickshell duplicate guard | `qs --no-duplicate --config arch-wm`; `qs list --all` | PASS (exit 0, “An instance ... already running”, count remains one) | `qs-duplicate`, `final-daemon` |
| OPEN-CLOSE-TRIGGER | control-center opens once, trigger closes | compositor pointer input | Attempted with available binaries; `wlrctl`, `ydotool`, `dotool`, `xdotool`, `swaymsg`, `wev` absent | BLOCKED — no installed pointer automation; no truthful click invocation available | `input-automation`, `open-attempt-shot`, `layers-open-attempt` |
| OUTSIDE-DISMISS | outside click closes | compositor pointer input | Same unavailable pointer automation surface | BLOCKED — no pointer injection tool | `input-automation` |
| ESCAPE-DISMISS | Escape closes | keyboard input | `wtype -k Escape` (exit 0), then fresh `grim` and `hyprctl layers -j` | NOT_RUN — menu could not be opened; Escape attempt leaves closed state/layers unchanged | `escape-attempt`, `after-escape-shot`, `layers-after-escape` |
| CARD-SHIELD | click inside card does not dismiss | compositor pointer input | Same unavailable pointer automation surface | BLOCKED — no pointer injection tool | `input-automation` |

### adversarialCases

| scenario id | criterion reference | adversarial class | expected behavior | verdict | artifactRefs |
|---|---|---|---|---|---|
| ADV-STALE | managed payload freshness | stale_state | Installed sentinels equal source sentinels after deployment | PASS — Hyprland `2026.08.04.3`; shell `2026.08.06.5` on both source and installed paths | `sentinels` |
| ADV-DIRTY | preserve unrelated worktree changes | dirty_worktree | QA/deployment must not edit product files | PASS — git status contains only pre-existing scoped files plus `.omo/`; no QA product edits | `git-status` |
| ADV-MISLEAD | claimed startup must match runtime | misleading_success | Command exits and actual layer/process state agree | PASS — deploy exits 0; `qs list --all`/`ps` show one live PID; layers show one bar + one desktop surface | `deploy-50`, `deploy-60`, `final-daemon`, `layers-closed` |
| ADV-REPEAT | interruption/restart resilience | repeated_interruption | At least one replacement remains running at end | PASS — daemonized PID 217390 persists with PPID 1 after launcher exits | `final-daemon`, `qs-daemonize` |
| ADV-INPUT | unavailable automation | environment_capability | If pointer injector is absent, report blocker rather than infer interaction success | PASS (handled as limitation) — exact missing commands recorded; no inferred interaction verdict | `input-automation`, `open-attempt-shot` |

## artifactRefs

| id | kind | description | path |
|---|---|---|---|
| `deploy-50` | command transcript | Stage 50 deployment exit/output | `.omo/evidence/interaction-repair/deploy-50.txt` |
| `deploy-60` | command transcript | Stage 60 deployment exit/output | `.omo/evidence/interaction-repair/deploy-60.txt` |
| `sentinels` | text receipt | Source vs installed managed-version sentinels | `.omo/evidence/interaction-repair/sentinels.txt` |
| `live-qs-log` | runtime log | Prescribed guarded launch/config-loaded log | `.omo/evidence/interaction-repair/live-qs.log` |
| `qs-daemonize` | runtime log | Native daemonized replacement launch log | `.omo/evidence/interaction-repair/qs-daemonize.log` |
| `final-daemon` | process transcript | Final one-instance `qs list`, `pgrep`, and PPID=1 receipt | `.omo/evidence/interaction-repair/final-daemon-receipt.txt` |
| `qs-duplicate` | command transcript | Second `--no-duplicate` invocation and unchanged count | `.omo/evidence/interaction-repair/qs-duplicate-attempt.log` |
| `layers-closed` | JSON + command output | Final closed-state Hyprland layers (bar + desktop geometry) | `.omo/evidence/interaction-repair/layers-final-closed.json` |
| `layers-open-attempt` | JSON | Post-attempt layers; no full-screen popup layer | `.omo/evidence/interaction-repair/layers-open-attempt.json` |
| `layers-after-escape` | JSON | Post-Escape layers; unchanged closed state | `.omo/evidence/interaction-repair/layers-after-escape.json` |
| `closed-shot` | screenshot | Fresh desktop before/closed state | `.omo/evidence/interaction-repair/desktop-closed-daemon.png` |
| `open-attempt-shot` | screenshot | Fresh screenshot after documented unavailable-input attempt | `.omo/evidence/interaction-repair/desktop-open-attempt-unavailable.png` |
| `after-escape-shot` | screenshot | Fresh screenshot after `wtype -k Escape` | `.omo/evidence/interaction-repair/desktop-after-escape.png` |
| `topright-crop` | screenshot crop | Top-right layer visual inspection | `.omo/evidence/interaction-repair/desktop-topright-crop.png` |
| `input-automation` | capability transcript | Exact installed/missing automation commands and limitation | `.omo/evidence/interaction-repair/input-automation.txt` |
| `escape-attempt` | command transcript | `wtype -k Escape` exit receipt | `.omo/evidence/interaction-repair/escape-attempt.txt` |
| `git-status` | git transcript | Worktree state observed during QA | `.omo/evidence/interaction-repair/git-status.txt` |

