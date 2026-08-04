#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

for command in git rsync python; do
  command -v "$command" >/dev/null || {
    echo "Missing required command: $command" >&2
    exit 1
  }
done

git clone --depth=1 https://github.com/grapes7000/themes.git "$TMP_DIR/themes"
git clone --depth=1 https://github.com/grapes7000/hyprland-setup.git "$TMP_DIR/hyprland"

mkdir -p "$ROOT_DIR/vendor/themes" "$ROOT_DIR/vendor/hyprland"

rsync -a --delete --exclude='.git/' \
  "$TMP_DIR/themes/" "$ROOT_DIR/vendor/themes/"

rsync -a --delete \
  --exclude='.git/' \
  --exclude='eww/' \
  --exclude='*/eww/' \
  --exclude='*/eww/**' \
  "$TMP_DIR/hyprland/" "$ROOT_DIR/vendor/hyprland/"

if find "$ROOT_DIR/vendor/hyprland" -type d -iname '*eww*' -o -type f -iname '*eww*' | grep -q .; then
  echo 'Refusing import: Eww content remains in vendor/hyprland.' >&2
  exit 1
fi

THEMES_SHA="$(git -C "$TMP_DIR/themes" rev-parse HEAD)"
HYPR_SHA="$(git -C "$TMP_DIR/hyprland" rev-parse HEAD)"
SYNCED_AT="$(date --utc +%Y-%m-%dT%H:%M:%SZ)"

python - "$ROOT_DIR/vendor/UPSTREAM_LOCK.json" "$THEMES_SHA" "$HYPR_SHA" "$SYNCED_AT" <<'PY'
import json
import pathlib
import sys

path, themes_sha, hypr_sha, synced_at = sys.argv[1:]
payload = {
    "synced_at": synced_at,
    "themes": {
        "repository": "grapes7000/themes",
        "commit": themes_sha,
    },
    "hyprland": {
        "repository": "grapes7000/hyprland-setup",
        "commit": hypr_sha,
        "eww_excluded": True,
    },
}
pathlib.Path(path).write_text(json.dumps(payload, indent=2) + "\n")
PY

"$ROOT_DIR/scripts/check-no-eww.sh"
echo "Synced themes@$THEMES_SHA and hyprland-setup@$HYPR_SHA"
