#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

scan_roots=(
  "$ROOT_DIR/modules"
  "$ROOT_DIR/vendor/hyprland"
  "$ROOT_DIR/installer"
  "$ROOT_DIR/manifests"
)

matches="$(find "${scan_roots[@]}" -iname '*eww*' -print 2>/dev/null || true)"

if [[ -n "$matches" ]]; then
  echo 'Unexpected legacy Eww paths found in managed source directories:' >&2
  printf '%s\n' "$matches" >&2
  exit 1
fi

echo 'Managed source directories are free of Eww paths.'
