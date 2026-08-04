-- Safe fallback. The theme command atomically replaces this file.
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
    },
    decoration = {
        rounding = 6,
        active_opacity = 1.0,
        inactive_opacity = 0.96,
        blur = { enabled = true, size = 6, passes = 2 },
        shadow = { enabled = true, range = 20, render_power = 3, color = 0x66000000 },
    },
})
