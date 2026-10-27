-- Opt-in behavior fragment for the repository's Lua-based Hyprland setup.
-- Load AFTER the base rules. No monitor names, machine IDs, or theme data.
hl.window_rule({
    name = "brooke-floating-first",
    match = { class = ".*" },
    float = true,
    center = true,
})
-- Use the existing togglefloating binding to arrange an individual window.
-- Quickshell's window-controls panel supplies maximize/minimize/restore/close.
