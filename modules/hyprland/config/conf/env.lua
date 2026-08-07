archwm.terminal = "kitty"
archwm.file_manager = "kitty --class yazi -e yazi"
archwm.menu = "fuzzel"

local environment = {
    XDG_CURRENT_DESKTOP = "Hyprland",
    XDG_SESSION_TYPE = "wayland",
    XDG_SESSION_DESKTOP = "Hyprland",
    QT_QPA_PLATFORM = "wayland;xcb",
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
    MOZ_ENABLE_WAYLAND = "1",
    ELECTRON_OZONE_PLATFORM_HINT = "auto",
    NIXOS_OZONE_WL = "1",
    SDL_VIDEODRIVER = "wayland",
    CLUTTER_BACKEND = "wayland",
    QS_ICON_THEME = "char-white",
}

for name, value in pairs(environment) do
    hl.env(name, value)
end
