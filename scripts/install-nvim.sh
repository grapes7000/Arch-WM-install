#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/modules/nvim/config"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
TARGET="$CONFIG_HOME/nvim"
BACKUP_ROOT="$DATA_HOME/arch-wm-install/backups"

for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then
    echo "  DRY RUN: would install Neovim config and sync plugins"
    exit 0
  fi
done

if ! command -v nvim >/dev/null 2>&1; then
  echo "  Neovim is not installed; skipping Neovim setup"
  exit 0
fi

if [[ ! -f "$SOURCE/init.lua" ]]; then
  echo "Neovim source config missing: $SOURCE/init.lua" >&2
  exit 1
fi

mkdir -p "$CONFIG_HOME" "$BACKUP_ROOT"

if [[ -e "$TARGET" || -L "$TARGET" ]]; then
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  backup="$BACKUP_ROOT/nvim-$stamp"
  echo "  backup $TARGET -> $backup"
  cp -a "$TARGET" "$backup"
fi

rm -rf "$TARGET"
mkdir -p "$TARGET"
cp -a "$SOURCE/." "$TARGET/"

echo "  installed Neovim config -> $TARGET"
echo "  syncing lazy.nvim plugins..."
nvim --headless "+Lazy! sync" +qa

echo "  ensuring Tree-sitter parsers..."
nvim --headless "+lua require('nvim-treesitter').install({'bash','c','cpp','css','diff','gitcommit','gitignore','html','javascript','json','lua','markdown','markdown_inline','python','toml','tsx','typescript','vim','vimdoc','yaml'}):wait(300000)" +qa

echo "  Neovim setup complete"
