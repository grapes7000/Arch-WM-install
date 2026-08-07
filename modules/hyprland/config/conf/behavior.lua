hl.config({
    -- preserve_split is a Hyprland behavior preference, not a theme aesthetic,
    -- so it's owned here rather than by the theme engine's generated
    -- dwindle{}/master{} block (see theme_components.py render_hypr/render_hypr_lua).
    dwindle = {
        preserve_split = true,
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        focus_on_activate = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
    binds = {
        scroll_event_delay = 250,
        workspace_back_and_forth = true,
        window_direction_monitor_fallback = true,
    },
    xwayland = {
        force_zero_scaling = false,
    },
})
