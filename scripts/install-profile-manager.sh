#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/arch-wm-install/profile-manager"
BIN="$HOME/.local/bin"

mkdir -p "$DEST/lib" "$BIN"
rm -rf "$DEST/lib/desktop_manager"
cp -a "$ROOT_DIR/desktop_manager" "$DEST/lib/desktop_manager"
cp "$ROOT_DIR/schemas/desktop-profile.schema.json" "$DEST/desktop-profile.schema.json"

cat > "$BIN/desktopctl" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
export PYTHONPATH="$DEST/lib\${PYTHONPATH:+:\$PYTHONPATH}"
exec python -m desktop_manager "\$@"
EOF
chmod 0755 "$BIN/desktopctl"

printf 'Installed optional desktop profile manager.\n'
printf '  CLI: %s\n' "$BIN/desktopctl"
printf '  Start with: desktopctl catalog\n'
printf 'Nothing was fetched, installed, activated, or changed in Hyprland.\n'
