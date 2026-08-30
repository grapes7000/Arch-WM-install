hl.on("hyprland.start", function()
    hl.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
    )
    hl.exec_cmd(
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
    )
    hl.exec_cmd(
        "test -x /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 && "
        .. "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
    )
    hl.exec_cmd("command -v nm-applet >/dev/null 2>&1 && nm-applet --indicator")
    hl.exec_cmd("command -v udiskie >/dev/null 2>&1 && udiskie --tray")
    hl.exec_cmd("command -v hyprpaper >/dev/null 2>&1 && hyprpaper")
    hl.exec_cmd("command -v hypridle >/dev/null 2>&1 && hypridle")
    hl.exec_cmd("command -v dunst >/dev/null 2>&1 && dunst")
    hl.exec_cmd(
        "command -v arch-wm-regreet-theme >/dev/null 2>&1 && "
        .. "arch-wm-regreet-theme --watch"
    )
    hl.exec_cmd(
        "pkill -f '/.config/hypr/scripts/theme-sync.py' >/dev/null 2>&1 || true; "
        .. "python ~/.config/hypr/scripts/theme-sync.py >/dev/null 2>&1 &"
    )
    hl.exec_cmd(
        "sh ~/.config/hypr/scripts/ensure-quickshell-default.sh; "
        .. "command -v qs >/dev/null 2>&1 && qs --no-duplicate --config arch-wm"
    )
end)
