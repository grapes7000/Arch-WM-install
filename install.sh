#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

cat <<'EOF'
Arch WM Install is currently an implementation scaffold, not a production installer.

A coding agent must complete the staged installer described in AGENTS.md and
docs/INSTALLER.md before this script is used on a real machine.

Safe commands available now:
  ./scripts/sync-upstreams.sh
  ./scripts/check-legacy-widget-free.sh
  python ./scripts/validate-layouts.py
  python -m unittest discover -s tests
EOF

exit 2
