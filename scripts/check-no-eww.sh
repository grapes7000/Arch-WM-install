#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

matches="$(find "$ROOT_DIR" \
  -path "$ROOT_DIR/.git" -prune -o \
  -path "$ROOT_DIR/docs" -prune -o \
  -path "$ROOT_DIR/AGENTS.md" -prune -o \
  -iname '*eww*' -print)"

if [[ -n "$matches" ]]; then
  echo 'Unexpected Eww paths found:' >&2
  printf '%s\n' "$matches" >&2
  exit 1
fi

echo 'No Eww paths found in managed source directories.'
