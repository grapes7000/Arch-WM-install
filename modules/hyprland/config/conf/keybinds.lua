local main = "SUPER"

hl.bind(main .. " + Return", hl.dsp.exec_cmd(archwm.terminal), {
    description = "Open terminal",
})
hl.bind(main .. " + Space", hl.dsp.exec_cmd("qs -c arch-wm ipc call launcher toggle"), {
    description = "Open application launcher",
})
hl.bind(main .. " + E", hl.dsp.exec_cmd(archwm.file_manager), {
    description = "Open terminal file manager",
})
hl.bind(main .. " + Q", hl.dsp.window.close(), {
    description = "Close active window",
})
hl.bind(main .. " + V", hl.dsp.window.float({ action = "toggle" }), {
    description = "Toggle floating window",
})
hl.bind(main .. " + F", hl.dsp.window.fullscreen({
    mode = "fullscreen",
    action = "toggle",
}), {
    description = "Toggle fullscreen",
})
hl.bind(main .. " + M", hl.dsp.window.fullscreen({
    mode = "maximized",
    action = "toggle",
}), {
    description = "Toggle maximized",
})
hl.bind(main .. " + L", hl.dsp.exec_cmd("loginctl lock-session"), {
    description = "Lock session",
})
hl.bind(main .. " + SHIFT + E", hl.dsp.exec_cmd(
    "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"
), {
    description = "Exit Hyprland safely",
})
hl.bind(main .. " + T", hl.dsp.exec_cmd("kitty --class theme-picker -e term theme"), {
    description = "Choose desktop theme",
})
hl.bind(main .. " + D", hl.dsp.exec_cmd("qs -c arch-wm ipc call homepage toggle"), {
    description = "Toggle homepage dashboard",
})
hl.bind(main .. " + G", hl.dsp.exec_cmd("kitty --class lazygit -e lazygit"), {
    description = "Open Lazygit",
})

local directions = {
    H = "left",
    J = "down",
    K = "up",
    L = "right",
    left = "left",
    down = "down",
    up = "up",
    right = "right",
}

for key, direction in pairs(directions) do
    hl.bind(main .. " + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind(main .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end

for workspace = 1, 10 do
    local key = workspace % 10
    hl.bind(main .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(main .. " + SHIFT + " .. key, hl.dsp.window.move({
        workspace = workspace,
        follow = false,
    }))
end

-- Dedicated special workspaces keep frequently-used apps close without
-- consuming the numbered workspace strip. The shell can call the same
-- special-workspace names through hyprctl later without duplicating policy.
local special_workspaces = {
    Z = "scratch",
    N = "music",
    C = "comms",
}

for key, workspace in pairs(special_workspaces) do
    hl.bind(main .. " + " .. key, hl.dsp.workspace.toggle_special(workspace), {
        description = "Toggle " .. workspace .. " special workspace",
    })
    hl.bind(main .. " + SHIFT + " .. key, hl.dsp.window.move({
        workspace = "special:" .. workspace,
    }), {
        description = "Move window to " .. workspace .. " special workspace",
    })
end

hl.bind(main .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(main .. " + mouse:272", hl.dsp.window.drag(), { drag = true, non_consuming = true })
hl.bind(main .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("Print", hl.dsp.exec_cmd(
    "mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png"
), {
    description = "Capture full screen",
})
hl.bind(main .. " + S", hl.dsp.exec_cmd(
    "mkdir -p ~/Pictures/Screenshots && grim -g \"$(slurp)\" ~/Pictures/Screenshots/region-$(date +%Y%m%d-%H%M%S).png"
), {
    description = "Capture selected region",
})

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(
    "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(
    "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(
    "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(
    "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(
    "brightnessctl -e4 -n2 set 5%+"
), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(
    "brightnessctl -e4 -n2 set 5%-"
), { locked = true, repeating = true })
