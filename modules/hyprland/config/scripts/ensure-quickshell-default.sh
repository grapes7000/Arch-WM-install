#!/usr/bin/env sh
set -eu

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
quickshell_root="$config_home/quickshell"
arch_wm="$quickshell_root/arch-wm"
default_config="$quickshell_root/default"

# Arch-WM has not been installed yet; do not create a dangling default alias.
if [ ! -d "$arch_wm" ]; then
    exit 1
fi

mkdir -p "$quickshell_root"

if [ -L "$default_config" ]; then
    current_target=$(readlink "$default_config" 2>/dev/null || true)
    case "$current_target" in
        arch-wm|./arch-wm|"$arch_wm")
            exit 0
            ;;
    esac
    printf 'Arch-WM: leaving existing Quickshell default symlink untouched: %s -> %s\n' \
        "$default_config" "$current_target" >&2
    exit 1
fi

if [ -e "$default_config" ]; then
    printf 'Arch-WM: leaving existing Quickshell default config untouched: %s\n' \
        "$default_config" >&2
    exit 1
fi

# Relative target keeps the alias portable if XDG_CONFIG_HOME moves.
ln -s arch-wm "$default_config"
