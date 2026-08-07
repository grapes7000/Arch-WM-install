# Interaction repair verification

All commands below were re-run after the scoped patch. Their complete stdout,
stderr, and exit status are captured in the linked files.

| Success criterion | Invocation | Observable | Artifact |
| --- | --- | --- | --- |
| Popup and bar QML parse cleanly | `qmllint -I modules/shell modules/shell/components/MenuPopup.qml modules/shell/surfaces/bar/BarSurface.qml` | `EXIT:0` | `reverify-qmllint.txt` |
| Layout contracts remain valid | `python scripts/validate-layouts.py` | 11 manifests and generated registry valid; `EXIT:0` | `reverify-layouts.txt` |
| Structural interaction regressions pass | `python -m unittest discover -s tests -v` | 17 tests, including duplicate guard and popup dismissal contracts, pass; `EXIT:0` | `reverify-unittest.txt` |
| VM smoke script remains portable Bash | `bash -n scripts/vm-smoke-test.sh` | `EXIT:0` | `reverify-bash-n.txt` |
| Guarded startup and sentinels are exact | `grep` and `cat` contract probe | guarded command appears in autostart and smoke script; `qs list --all` and exact config-path count are present; versions are `2026.08.04.3` and `2026.08.06.5`; `EXIT:0` | `reverify-contracts.txt` |
| Static popup surface behavior | `sed -n '10,78p' modules/shell/components/MenuPopup.qml` | Four-edge transparent `PanelWindow`; full-parent backdrop calls `close()`; focused item sends Escape to `close()`; card is top-right at width 340; card click shield consumes clicks; `EXIT:0` | `reverify-static-popup-inspection.txt` |

The requested live deployment/restart was not run. Static QML inspection is the
manual-QA surface requested for this task; live interaction remains for the
parent agent's QA.
