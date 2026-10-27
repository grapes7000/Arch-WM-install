#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export PYTHONPATH="$ROOT_DIR${PYTHONPATH:+:$PYTHONPATH}"
export PATH="$HOME/.local/bin:$PATH"

run_install() {
  # Portable Neovim configuration is owned by grapes7000/dotfiles and applied
  # through linux-setup/Chezmoi. Arch-WM-install only owns desktop/session setup.
  # This development branch boots Brooke's desktop by default.
  local has_profile=false
  for arg in "$@"; do
    case "$arg" in --profile|--profile=*) has_profile=true ;; esac
  done
  if [[ "$has_profile" == false ]]; then
    set -- --profile brooke "$@"
  fi
  python -m installer install "$@"
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
    exec python -m installer "$command" "$@"
    ;;
  *)
    run_install "$@"
    ;;
esac
