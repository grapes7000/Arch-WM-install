#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export PYTHONPATH="$ROOT_DIR${PYTHONPATH:+:$PYTHONPATH}"
export PATH="$HOME/.local/bin:$PATH"
case "${1:-install}" in
  install)
    shift
    exec python -m installer install "$@"
    ;;
  help|doctor)
    command="$1"
    shift
    exec python -m installer "$command" "$@"
    ;;
  *)
    exec python -m installer install "$@"
    ;;
esac
