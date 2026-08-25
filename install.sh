#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export PYTHONPATH="$ROOT_DIR${PYTHONPATH:+:$PYTHONPATH}"
export PATH="$HOME/.local/bin:$PATH"

run_install() {
  python -m installer install "$@"
  bash "$ROOT_DIR/scripts/install-nvim.sh" "$@"
}

case "${1:-install}" in
  install)
    shift
    run_install "$@"
    ;;
  profile-manager)
    shift
    if (($#)); then
      echo "profile-manager takes no options yet; install it, then use desktopctl" >&2
      exit 2
    fi
    exec bash "$ROOT_DIR/scripts/install-profile-manager.sh"
    ;;
  help|doctor)
    command="$1"
    shift
    exec python -m installer "$command" "$@"
    ;;
  *)
    run_install "$@"
    ;;
esac
