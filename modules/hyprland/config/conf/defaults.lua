-- Safe first-boot appearance. generated/theme.lua overrides these values.
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgba(00e5ffff)", "rgba(ff1493ff)" },
                angle = 45,
            },
            inactive_border = "rgba(ff1493aa)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 6,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.96,
        shadow = {
            enabled = true,
            range = 20,
            render_power = 3,
            color = 0x66000000,
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            vibrancy = 0.16,
        },
    },
    animations = {
        enabled = true,
    },
})

hl.curve("archEase", {
    type = "bezier",
    points = { { 0.16, 1 }, { 0.3, 1 } },
})
hl.curve("archLinear", {
    type = "bezier",
    points = { { 0, 0 }, { 1, 1 } },
})

hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "archEase" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "archEase" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "archEase", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "archLinear", style = "popin 92%" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "archEase" })
hl.animation({ leaf = "layers", enabled = true, speed = 5, bezier = "archEase" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "archEase", style = "slide" })
