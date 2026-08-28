#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
THEME_ROOT="$CONFIG_HOME/theme-engine"
THEME_DIR="$THEME_ROOT/themes"
UI_STYLE_DIR="$THEME_ROOT/ui-styles/bundled"

mkdir -p "$THEME_DIR" "$UI_STYLE_DIR"

theme_count=0
for source in "$ROOT"/modules/theme-engine/schema/reference-themes/*.json; do
  [[ -e "$source" ]] || continue
  install -m 0644 "$source" "$THEME_DIR/$(basename "$source")"
  theme_count=$((theme_count + 1))
done

style_count=0
for source in "$ROOT"/modules/theme-engine/ui-styles/*.json; do
  [[ -e "$source" ]] || continue
  install -m 0644 "$source" "$UI_STYLE_DIR/$(basename "$source")"
  style_count=$((style_count + 1))
done

echo "Synced $theme_count bundled themes and $style_count UI styles."
echo "Try: ui-style atelier"
echo "Then: theme monolith-dark"
