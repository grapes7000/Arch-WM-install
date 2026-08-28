#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export PYTHONPATH="$ROOT_DIR${PYTHONPATH:+:$PYTHONPATH}"
export PATH="$HOME/.local/bin:$PATH"

run_install() {
  python -m installer.fixed_entry install "$@"
  bash "$ROOT_DIR/scripts/install-nvim.sh" "$@"
}

command="${1:-install}"
case "$command" in
  install)
    if [[ "${1:-}" == "install" ]]; then
      shift
    fi
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
    shift
    exec python -m installer.fixed_entry "$command" "$@"
    ;;
  *)
    run_install "$@"
    ;;
esac
