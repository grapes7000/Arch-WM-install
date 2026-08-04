#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-preflight}"
PROFILE="${ARCH_WM_PROFILE:-desktop}"
THEME="${ARCH_WM_THEME:-y2k}"

heading() {
  printf '\n== %s ==\n' "$*"
}

static_checks() {
  heading 'Python and layout validation'
  python "$ROOT_DIR/scripts/validate-layouts.py"
  python -m unittest discover -s "$ROOT_DIR/tests" -v

  heading 'Shell syntax'
  bash -n "$ROOT_DIR/install.sh" "$ROOT_DIR/uninstall.sh" "$ROOT_DIR"/scripts/*.sh
  "$ROOT_DIR/scripts/check-legacy-widget-free.sh"

  heading 'Python syntax'
  python -m compileall -q "$ROOT_DIR/installer" "$ROOT_DIR/modules/theme-engine/bin/theme"
}

case "$MODE" in
  preflight)
    static_checks
    heading 'Installer dry run'
    "$ROOT_DIR/install.sh" \
      --profile "$PROFILE" \
      --theme "$THEME" \
      --dry-run \
      --noninteractive
    printf '\nPreflight passed. No system changes were made.\n'
    ;;

  install)
    static_checks
    heading 'Install desktop into this disposable Arch VM'
    "$ROOT_DIR/install.sh" \
      --profile "$PROFILE" \
      --theme "$THEME" \
      --noninteractive
    heading 'Installer doctor'
    PYTHONPATH="$ROOT_DIR${PYTHONPATH:+:$PYTHONPATH}" \
      python -m installer doctor --profile "$PROFILE" --theme "$THEME"
    printf '\nInstall stage passed. Start or restart Hyprland, then run:\n'
    printf '  %q post-login\n' "$0"
    ;;

  post-login)
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || {
      echo 'Run post-login from a terminal inside the installed Hyprland session.' >&2
      exit 1
    }

    heading 'Hyprland configuration'
    config_errors="$(hyprctl configerrors)"
    if [[ -n "$config_errors" ]]; then
      printf '%s\n' "$config_errors" >&2
      exit 1
    fi
    echo 'No Hyprland configuration errors.'

    heading 'Installed shell processes'
    if pgrep -af 'qs.*arch-wm' >/dev/null; then
      pgrep -af 'qs.*arch-wm'
    else
      echo 'Arch WM Quickshell process is not running.' >&2
      echo 'Launch it manually with: qs -c arch-wm' >&2
      exit 1
    fi

    heading 'Theme outputs'
    for path in \
      "$HOME/.config/theme-engine/generated/theme.json" \
      "$HOME/.config/hypr/generated/theme.lua" \
      "$HOME/.config/kitty/generated/theme.conf" \
      "$HOME/.config/theme-engine/generated/starship.toml"; do
      [[ -s "$path" ]] || {
        echo "Missing generated file: $path" >&2
        exit 1
      }
      echo "OK $path"
    done

    heading 'Portable widget placements'
    grep -q '"widget": "clock"' \
      "$HOME/.config/quickshell/arch-wm/layouts/bar.default.json"
    grep -q '"widget": "clock"' \
      "$HOME/.config/quickshell/arch-wm/layouts/desktop.default.json"
    echo 'The same clock package is assigned to bar and desktop layouts.'

    heading 'Lock boundary'
    [[ -s "$HOME/.config/hypr/hyprlock.conf" ]]
    [[ -s "$HOME/.config/hypr/hypridle.conf" ]]
    echo 'Hyprlock is the authentication boundary; custom Quickshell lock UI is disabled.'

    printf '\nFirst VM smoke test passed.\n'
    ;;

  rollback)
    heading 'Preview rollback'
    "$ROOT_DIR/uninstall.sh" --dry-run --profile "$PROFILE" --theme "$THEME"
    echo
    echo 'To perform the tracked rollback in this disposable VM:'
    printf '  %q --profile %q --theme %q\n' "$ROOT_DIR/uninstall.sh" "$PROFILE" "$THEME"
    ;;

  *)
    echo "Usage: $0 {preflight|install|post-login|rollback}" >&2
    exit 2
    ;;
esac
