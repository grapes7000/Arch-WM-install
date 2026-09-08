#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="${ARCH_WM_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/arch-wm"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/arch-wm-install"
BACKUPS="${XDG_DATA_HOME:-$HOME/.local/share}/arch-wm-install/manual-backups"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$STATE/quickshell-force-repair.log"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Install the shell from the local checkout (the same source the installer
# stages), never from a remote branch: stale branches were the cause of
# reverting newer shell work.
SOURCE="$ROOT/modules/shell"
REF="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "$ROOT")"

if grep -R -n -F 'required property var context' "$SOURCE/widgets"; then
    echo 'Repair aborted: remote branch still contains required widget contexts.' >&2
    exit 1
fi

if [[ -e "$TARGET" ]]; then
    mkdir -p "$BACKUPS/$STAMP"
    cp -a "$TARGET" "$BACKUPS/$STAMP/arch-wm"
fi

rm -rf "$TARGET"
mkdir -p "$(dirname "$TARGET")"
cp -a "$SOURCE" "$TARGET"

if grep -R -n -F 'required property var context' "$TARGET/widgets"; then
    echo 'Repair failed: stale widget files remain installed.' >&2
    exit 1
fi

mkdir -p "$STATE"
qs kill -c arch-wm >/dev/null 2>&1 || true
# A crashed Quickshell process may spend up to ten seconds in its recovery
# path before registering a replacement instance. Require an uninterrupted
# quiet window after the last recovered instance is stopped.
quiet_ticks=0
for _ in {1..300}; do
    if qs list -c arch-wm 2>/dev/null | grep -q '^Instance '; then
        qs kill -c arch-wm >/dev/null 2>&1 || true
        quiet_ticks=0
    else
        quiet_ticks=$((quiet_ticks + 1))
        if ((quiet_ticks >= 110)); then
            break
        fi
    fi
    sleep 0.1
done
if ((quiet_ticks < 110)); then
    echo 'Repair aborted: Quickshell did not remain stopped.' >&2
    exit 1
fi
nohup qs --no-duplicate --config arch-wm >"$LOG" 2>&1 &
sleep 3

if grep -Fq 'Required property context was not initialized' "$LOG"; then
    echo 'Quickshell still loaded a different stale configuration:' >&2
    tail -n 40 "$LOG" >&2
    exit 1
fi

if grep -Eq '^ERROR:|Failed to load configuration' "$LOG"; then
    echo 'Quickshell reported a new startup error:' >&2
    tail -n 40 "$LOG" >&2
    exit 1
fi

printf 'Repaired shell installed from %s.\n' "$REF"
printf 'Log: %s\n' "$LOG"
